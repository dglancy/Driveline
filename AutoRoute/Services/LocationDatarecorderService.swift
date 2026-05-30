//
//  LocationDatarecorderService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Combine
import CoreLocation
import SwiftData
import os.log

// MARK: - Location Data Recorder Service

@MainActor
final class LocationDataRecorderService: ObservableObject {

  // MARK: - Properties

  private let locationService: LocationService
  private let modelContext: ModelContext
  private var locationCancellable: AnyCancellable?
  private(set) var route: Route?

  // MARK: - Lifecycle

  init(locationService: LocationService, modelContext: ModelContext) {
    self.locationService = locationService
    self.modelContext = modelContext
  }

  // MARK: - Actions

  func startRecording(with route: Route) {
    Log.data.info("Starting recording locations")
    self.route = route
    route.isRecording = true
    modelContext.insert(route)

    do {
      try modelContext.save()
      Log.data.info("Saved starting recording locations")
    } catch {
      Log.data.error("Failed to save starting recording locations: \(error)")
    }

    locationCancellable = locationService.locationPublisher
      .sink { [weak self] location in
        self?.persist(location)
      }

    Log.data.info("Started recording locations")
  }

  func stopRecording() {
    Log.data.info("Stopping recording locations")
    locationCancellable = nil

    guard let route else { return }

    route.isRecording = false

    do {
      try modelContext.save()
      Log.data.info("Saved stopping recording locations")
    } catch {
      Log.data.error("Failed to save stopping recording locations: \(error)")
    }

    self.route = nil
    Log.data.info("Stopped recording locations")
  }

  // MARK: - Private functions

  private func persist(_ location: CLLocation) {
    Log.data.info("Saving a new location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

    guard let route else { return }

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

    route.positions.append(position)

    do {
      try modelContext.save()
      Log.data.info("Saved a new location as a position: \(position.latitude), \(position.longitude)")
    } catch {
      Log.data.error("Failed to save position: \(error)")
    }
  }
}
