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
  @ObservationIgnored private let networkMonitorService: any NetworkMonitorServiceProtocol
  @ObservationIgnored private var userPreferences: UserPreferences
  @ObservationIgnored private var liveActivityCancellable: AnyCancellable?
  @ObservationIgnored private var startGeocodeCancellable: AnyCancellable?
  @ObservationIgnored private var networkCancellable: AnyCancellable?
  #if os(iOS)
  @ObservationIgnored private let activityService = DriveActivityService()
  #endif

  // MARK: - Lifecycle

  init(modelContext: ModelContext,
       locationService: LocationService,
       locationDataRecorder: LocationDataRecorderService,
       geocodingService: any GeocodingServiceProtocol = GeocodingService(),
       networkMonitorService: any NetworkMonitorServiceProtocol = NetworkMonitorService(),
       userPreferences: UserPreferences = UserPreferences(),
       initialDrive: Drive? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.geocodingService = geocodingService
    self.networkMonitorService = networkMonitorService
    self.userPreferences = userPreferences
    self.drive = initialDrive

    networkCancellable = networkMonitorService.connectivityRestoredPublisher
      .sink { [weak self] in
        Task { 
          guard let self else { return }
          await self.retryNilPlaceNamesOnConnectivity()
        }
      }
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

    startGeocodeCancellable = locationService.locationPublisher
      .first()
      .sink { [weak self] location in
        Task { [weak self] in
          guard let self, let drive = self.drive else { return }
          drive.startPlaceName = await self.geocodingService.reverseGeocode(location: location)
          self.saveModelContext()
          self.updateLiveActivity()
        }
      }

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

    #if os(iOS)
    activityService.startActivity(for: drive)
    #endif
  }

  private func findRecentlyFinishedDrive() -> Drive? {
    let cutoff = Date().addingTimeInterval(kRecentDriveCutoff)
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
    locationService.stop()

    if let drive {
      drive.endedAt = Date()
      drive.status = .finished
      locationDataRecorder.stopRecording()
      saveModelContext()

      if let last = drive.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        Task { [weak self] in
          guard let self else { return }
          drive.endPlaceName = await geocodingService.reverseGeocode(location: location)
          saveModelContext()
        }
      }
    }

    self.drive = nil

    #if os(iOS)
    Task { await activityService.endActivity() }
    #endif
  }

  func checkAndRetryNilPlaceNamesForFinishedDrives() async {
    guard networkMonitorService.isConnected else { return }
    let cutoff = Date().addingTimeInterval(kDriveAgeCutoff)
    let finishedStatus = Drive.DriveStatus.finished
    let descriptor = FetchDescriptor<Drive>(
      predicate: #Predicate<Drive> { drive in
        drive.startedAt >= cutoff && drive.status == finishedStatus
      }
    )
    guard let candidates = try? modelContext.fetch(descriptor) else { return }
    let needsRetry = candidates.filter { $0.startPlaceName == nil || $0.endPlaceName == nil }
    guard !needsRetry.isEmpty else { return }
    for finishedDrive in needsRetry {
      if finishedDrive.startPlaceName == nil, let first = finishedDrive.orderedPositions.first {
        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        finishedDrive.startPlaceName = await geocodingService.reverseGeocode(location: location)
      }
      if finishedDrive.endPlaceName == nil, let last = finishedDrive.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        finishedDrive.endPlaceName = await geocodingService.reverseGeocode(location: location)
      }
      saveModelContext()
    }
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

  private func retryNilPlaceNamesOnConnectivity() async {
    if let activeDrive = drive, activeDrive.startPlaceName == nil,
       let first = activeDrive.orderedPositions.first {
      let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
      activeDrive.startPlaceName = await geocodingService.reverseGeocode(location: location)
      saveModelContext()
    }
    await checkAndRetryNilPlaceNamesForFinishedDrives()
  }

  private func saveModelContext() {
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context: \(error.localizedDescription)")
    }
  }
}
