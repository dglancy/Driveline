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
  private(set) var currentSpeedMs: Double?

  var isRecording: Bool { drive?.isRecording ?? false }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let locationDataRecorder: LocationDataRecorderService
  @ObservationIgnored private let geocodingService: any GeocodingServiceProtocol
  @ObservationIgnored private let networkMonitorService: any NetworkMonitorServiceProtocol
  @ObservationIgnored private var speedCancellable: AnyCancellable?
  @ObservationIgnored private var startGeocodeCancellable: AnyCancellable?
  @ObservationIgnored private var networkCancellable: AnyCancellable?

  // MARK: - Lifecycle

  init(modelContext: ModelContext,
       locationService: LocationService,
       locationDataRecorder: LocationDataRecorderService,
       geocodingService: any GeocodingServiceProtocol = GeocodingService(),
       networkMonitorService: any NetworkMonitorServiceProtocol = NetworkMonitorService(),
       initialDrive: Drive? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.geocodingService = geocodingService
    self.networkMonitorService = networkMonitorService
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
    let drive = Drive(name: driveNameForCurrentTime(), trigger: trigger)
    self.drive = drive
    currentSpeedMs = nil

    do {
      try locationDataRecorder.startRecording(with: drive)
    } catch {
      self.drive = nil
      throw error
    }
    locationService.start()

    speedCancellable = locationService.locationPublisher
      .sink { [weak self] location in
        self?.currentSpeedMs = location.speed >= 0 ? location.speed : nil
      }

    startGeocodeCancellable = locationService.locationPublisher
      .first()
      .sink { [weak self] location in
        Task { [weak self] in
          guard let self, let drive = self.drive else { return }
          drive.startPlaceName = await self.geocodingService.reverseGeocode(location: location)
          self.saveModelContext()
        }
      }
  }

  func finishDrive() {
    speedCancellable = nil
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

    currentSpeedMs = nil
    self.drive = nil
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

  private func retryNilPlaceNamesOnConnectivity() async {
    if let activeDrive = drive, activeDrive.startPlaceName == nil,
       let first = activeDrive.orderedPositions.first {
      let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
      activeDrive.startPlaceName = await geocodingService.reverseGeocode(location: location)
      saveModelContext()
    }
    await checkAndRetryNilPlaceNamesForFinishedDrives()
  }

  private func driveNameForCurrentTime() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12: return String(localized: "Morning Drive", comment: "Default drive name for drives started between 05:00 and 11:59")
    case 12..<17: return String(localized: "Afternoon Drive", comment: "Default drive name for drives started between 12:00 and 16:59")
    case 17..<21: return String(localized: "Evening Drive", comment: "Default drive name for drives started between 17:00 and 20:59")
    default: return String(localized: "Night Drive", comment: "Default drive name for drives started between 21:00 and 04:59")
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
