//
//  DriveRecordingService.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import Foundation
import Observation
import SwiftData
import Combine

@MainActor
@Observable
final class DriveRecordingService {

  // MARK: - Properties

  private(set) var drive: Drive?

  var isRecording: Bool { drive?.status == .recording }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let locationDataRecorder: any LocationDataRecorderServiceProtocol
  @ObservationIgnored private let geocodingService: any GeocodingServiceProtocol
  @ObservationIgnored private let weatherService: any WeatherFetchServiceProtocol
  @ObservationIgnored private let placeNameSweepService: PlaceNameSweepService
  @ObservationIgnored private let spotlightIndexingService: SpotlightIndexingService?
  @ObservationIgnored private let categoryPredictionSweepService: CategoryPredictionSweepService
  @ObservationIgnored private var userPreferences: UserPreferences
  @ObservationIgnored private var liveActivityCancellable: AnyCancellable?
  @ObservationIgnored private var startGeocodeCancellable: AnyCancellable?
  @ObservationIgnored private var startWeatherCancellable: AnyCancellable?
  @ObservationIgnored private var finishTasks: [Task<Void, Never>] = []
  #if os(iOS)
  @ObservationIgnored private let activityService = DriveActivityService()
  #endif

  // MARK: - Lifecycle

  init(modelContext: ModelContext,
       locationService: LocationService,
       locationDataRecorder: any LocationDataRecorderServiceProtocol,
       geocodingService: any GeocodingServiceProtocol = GeocodingService(),
       weatherService: any WeatherFetchServiceProtocol = WeatherFetchService(),
       placeNameSweepService: PlaceNameSweepService? = nil,
       spotlightIndexingService: SpotlightIndexingService? = nil,
       categoryPredictionSweepService: CategoryPredictionSweepService? = nil,
       userPreferences: UserPreferences = UserPreferences(),
       initialDrive: Drive? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.geocodingService = geocodingService
    self.weatherService = weatherService
    self.placeNameSweepService = placeNameSweepService ?? PlaceNameSweepService(modelContainer: modelContext.container)
    self.spotlightIndexingService = spotlightIndexingService
    self.categoryPredictionSweepService = categoryPredictionSweepService ?? CategoryPredictionSweepService(modelContainer: modelContext.container)
    self.userPreferences = userPreferences
    self.drive = initialDrive
  }

  // MARK: - Actions

  func startDrive(trigger: Drive.RecordingTrigger = .manual) {
    cancelFinishTasks()

    if trigger == .automatic && userPreferences.continueDriveIfRecentlyFinished,
       let recentDrive = findRecentlyFinishedDrive() {
      resumeDrive(recentDrive)
    } else {
      createNewDrive(trigger: trigger)
    }
  }
  
  func finishDrive() {
    liveActivityCancellable = nil
    startGeocodeCancellable = nil
    startWeatherCancellable = nil
    locationService.stop()

    if let drive {
      drive.endedAt = Date()
      drive.status = .finished
      locationDataRecorder.stopRecording()
      modelContext.saveChanges()
      fetchEndWeather(for: drive)
      finishTasks.append(Task { await spotlightIndexingService?.indexDrive(drive) })
      let driveID = drive.persistentModelID
      finishTasks.append(Task { await categoryPredictionSweepService.classify(driveID: driveID) })
    }

    self.drive = nil

    finishTasks.append(Task { await placeNameSweepService.sweep() })

    #if os(iOS)
    finishTasks.append(Task { await activityService.endActivity() })
    #endif
  }

  // MARK: - Private functions

  private func cancelFinishTasks() {
    finishTasks.forEach { $0.cancel() }
    finishTasks.removeAll()
  }

  private func createNewDrive(trigger: Drive.RecordingTrigger) {
    let drive = Drive(trigger: trigger)
    self.drive = drive
    locationDataRecorder.startRecording(with: drive)
    beginTracking(drive)
  }

  private func resumeDrive(_ drive: Drive) {
    drive.status = .recording
    drive.endedAt = nil
    drive.endPlaceName = nil
    self.drive = drive
    modelContext.saveChanges()
    locationDataRecorder.startRecording(with: drive)
    beginTracking(drive)
  }

  private func beginTracking(_ drive: Drive) {
    locationService.start()

    liveActivityCancellable = locationService.locationPublisher
      .sink { [weak self] _ in
        self?.updateLiveActivity()
      }

    setupStartPlaceNameGeocoding(for: drive)
    setupStartWeather(for: drive)

    #if os(iOS)
    activityService.startActivity(for: drive)
    #endif
  }

  private func setupStartPlaceNameGeocoding(for drive: Drive) {
    guard drive.startPlaceName == nil else { return }
    startGeocodeCancellable = locationService.locationPublisher
      .first()
      .sink { [weak self] location in
        Task { [weak self] in
          guard let self, let drive = self.drive else { return }
          if let placeName = await self.geocodingService.reverseGeocode(location: location) {
            drive.startPlaceName = placeName
            self.modelContext.saveChanges()
            self.updateLiveActivity()
          }
        }
      }
  }

  private func findRecentlyFinishedDrive() -> Drive? {
    let cutoff = Date().addingTimeInterval(Constants.Configuration.recentDriveCutoff)
    var descriptor = FetchDescriptor<Drive>(
      sortBy: [SortDescriptor(\Drive.endedAt, order: .reverse)]
    )
    descriptor.fetchLimit = 10
    guard let drives = try? modelContext.fetch(descriptor) else { return nil }
    return drives.first {
      $0.status == .finished && ($0.endedAt.map { $0 >= cutoff } ?? false)
    }
  }

  private func updateLiveActivity() {
    #if os(iOS)
    guard let drive else { return }
    let elapsed = drive.activeDurationSeconds
    let avgSpeed = elapsed > 0 ? drive.accumulatedDistanceMetres / elapsed : 0
    let placeName = drive.startPlaceName
    let distance = drive.accumulatedDistanceMetres
    Task {
      await activityService.updateActivity(
        startPlaceName: placeName,
        distanceMetres: distance,
        avgSpeedMetresPerSecond: avgSpeed
      )
    }
    #endif
  }

  private func setupStartWeather(for drive: Drive) {
    guard drive.weatherReadings?.contains(where: { $0.type == .start }) != true else { return }
    startWeatherCancellable = locationService.locationPublisher
      .first()
      .sink { [weak self] location in
        Task { [weak self] in
          guard let self, let drive = self.drive else { return }
          do {
            let weather = try await self.weatherService.fetchWeather(at: location, type: .start)
            drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
            self.modelContext.saveChanges()
            Log.data.info("Start weather fetched: \(weather.conditionDescription), \(weather.temperatureCelsius)°C")
          } catch {
            Log.data.error("Start weather fetch failed: \(error)")
          }
        }
      }
  }

  private func fetchEndWeather(for drive: Drive) {
    guard let lastPosition = drive.orderedPositions.last else { return }
    let location = CLLocation(latitude: lastPosition.latitude, longitude: lastPosition.longitude)
    finishTasks.append(Task { [weak self] in
      guard let self else { return }
      do {
        let weather = try await self.weatherService.fetchWeather(at: location, type: .end)
        drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
        self.modelContext.saveChanges()
        Log.data.info("End weather fetched: \(weather.conditionDescription), \(weather.temperatureCelsius)°C")
      } catch {
        Log.data.error("End weather fetch failed: \(error)")
      }
    })
  }
}
