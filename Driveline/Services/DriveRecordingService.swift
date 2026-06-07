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

  var isRecording: Bool { drive?.isRecording ?? false }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let locationDataRecorder: LocationDataRecorderService
  @ObservationIgnored private let geocodingService: any GeocodingServiceProtocol
  @ObservationIgnored private let weatherService: any WeatherFetchServiceProtocol
  @ObservationIgnored private let placeNameSweepService: PlaceNameSweepService
  @ObservationIgnored private let weatherSweepService: WeatherSweepService
  @ObservationIgnored private let spotlightIndexingService: SpotlightIndexingService?
  @ObservationIgnored private var userPreferences: UserPreferences
  @ObservationIgnored private var liveActivityCancellable: AnyCancellable?
  @ObservationIgnored private var startGeocodeCancellable: AnyCancellable?
  @ObservationIgnored private var startWeatherCancellable: AnyCancellable?
  #if os(iOS)
  @ObservationIgnored private let activityService = DriveActivityService()
  #endif

  // MARK: - Lifecycle

  init(modelContext: ModelContext,
       locationService: LocationService,
       locationDataRecorder: LocationDataRecorderService,
       geocodingService: any GeocodingServiceProtocol = GeocodingService(),
       weatherService: any WeatherFetchServiceProtocol = WeatherFetchService(),
       placeNameSweepService: PlaceNameSweepService? = nil,
       weatherSweepService: WeatherSweepService? = nil,
       spotlightIndexingService: SpotlightIndexingService? = nil,
       userPreferences: UserPreferences = UserPreferences(),
       initialDrive: Drive? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.geocodingService = geocodingService
    self.weatherService = weatherService
    self.placeNameSweepService = placeNameSweepService ?? PlaceNameSweepService(modelContext: modelContext)
    self.weatherSweepService = weatherSweepService ?? WeatherSweepService(modelContext: modelContext)
    self.spotlightIndexingService = spotlightIndexingService
    self.userPreferences = userPreferences
    self.drive = initialDrive
  }

  // MARK: - Actions

  func startDrive(trigger: Drive.RecordingTrigger = .manual) throws {
    if trigger == .automatic && userPreferences.continueDriveIfRecentlyFinished,
       let recentDrive = findRecentlyFinishedDrive() {
      resumeDrive(recentDrive)
    } else {
      try createNewDrive(trigger: trigger)
    }
  }

  private func createNewDrive(trigger: Drive.RecordingTrigger) throws {
    let drive = Drive(trigger: trigger)
    self.drive = drive

    do {
      try locationDataRecorder.startRecording(with: drive)
    } catch {
      self.drive = nil
      throw error
    }
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

  private func resumeDrive(_ drive: Drive) {
    drive.status = .recording
    drive.endedAt = nil
    drive.endPlaceName = nil
    self.drive = drive
    saveModelContext()

    try? locationDataRecorder.startRecording(with: drive)
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
            self.saveModelContext()
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

  func finishDrive() {
    liveActivityCancellable = nil
    startGeocodeCancellable = nil
    startWeatherCancellable = nil
    locationService.stop()

    if let drive {
      drive.endedAt = Date()
      drive.status = .finished
      locationDataRecorder.stopRecording()
      saveModelContext()
      fetchEndWeather(for: drive)
      Task { await spotlightIndexingService?.indexDrive(drive) }
    }

    self.drive = nil

    Task { await placeNameSweepService.sweep() }
    Task { await weatherSweepService.sweep() }

    #if os(iOS)
    Task { await activityService.endActivity() }
    #endif
  }

  // MARK: - Private

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
    startWeatherCancellable = locationService.locationPublisher
      .first()
      .sink { [weak self] location in
        Task { [weak self] in
          guard let self, let drive = self.drive else { return }
          do {
            let weather = try await self.weatherService.fetchWeather(at: location, type: .start)
            drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
            self.saveModelContext()
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
    Task { [weak self] in
      guard let self else { return }
      do {
        let weather = try await self.weatherService.fetchWeather(at: location, type: .end)
        drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
        self.saveModelContext()
        Log.data.info("End weather fetched: \(weather.conditionDescription), \(weather.temperatureCelsius)°C")
      } catch {
        Log.data.error("End weather fetch failed: \(error)")
      }
    }
  }

  private func saveModelContext() {
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context: \(error.localizedDescription)")
    }
  }
}
