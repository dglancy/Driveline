//
//  LocationDatarecorderService.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Combine
import CoreLocation
import Observation
import SwiftData

// MARK: - Location Data Recorder Service

@MainActor
@Observable
final class LocationDataRecorderService {

  // MARK: - Properties

  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let saveInterval: TimeInterval
  @ObservationIgnored private var locationCancellable: AnyCancellable?
  @ObservationIgnored private var saveCancellable: AnyCancellable?
  @ObservationIgnored private var hasPendingPositions = false
  private(set) var drive: Drive?

  // MARK: - Lifecycle

  init(locationService: LocationService, modelContext: ModelContext, saveInterval: TimeInterval = 30) {
    self.locationService = locationService
    self.modelContext = modelContext
    self.saveInterval = saveInterval
  }

  // MARK: - Actions

  func startRecording(with drive: Drive) throws {
    guard self.drive == nil else {
      Log.data.error("startRecording called while already recording; ignoring.")
      return
    }
    Log.data.info("Starting recording locations")
    self.drive = drive
    modelContext.insert(drive)

    do {
      try modelContext.save()
      Log.data.info("Saved starting recording locations")
    } catch {
      modelContext.delete(drive)
      self.drive = nil
      Log.data.error("Failed to save starting recording locations: \(error)")
      throw error
    }

    locationCancellable = locationService.locationPublisher
      .sink { [weak self] location in
        self?.persist(location)
      }

    saveCancellable = Timer.publish(every: saveInterval, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] _ in self?.saveIfNeeded() }

    Log.data.info("Started recording locations")
  }

  func stopRecording() {
    Log.data.info("Stopping recording locations")
    locationCancellable = nil
    saveCancellable = nil
    saveIfNeeded()
    self.drive = nil
    Log.data.info("Stopped recording locations")
  }

  // MARK: - Private functions

  private func persist(_ location: CLLocation) {
    Log.data.info("Saving a new location: \(location.coordinate.latitude), \(location.coordinate.longitude)", privacy: .private)

    guard let drive else { return }

    let position = Position(
      timestamp: location.timestamp,
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude,
      altitude: location.altitude,
      horizontalAccuracy: location.horizontalAccuracy,
      verticalAccuracy: location.verticalAccuracy,
      course: location.course,
      courseAccuracy: location.courseAccuracy,
      speed: location.speed,
      speedAccuracy: location.speedAccuracy
    )

    drive.positions.append(position)
    hasPendingPositions = true
    Log.data.info("Queued new location: \(position.latitude), \(position.longitude)", privacy: .private)
  }

  private func saveIfNeeded() {
    guard hasPendingPositions else { return }
    modelContext.safeSave(
      onSuccess: {
        self.hasPendingPositions = false
        Log.data.info("Saved pending positions")
      },
      onFailure: { Log.data.error("Failed to save positions: \($0)") }
    )
  }
}
