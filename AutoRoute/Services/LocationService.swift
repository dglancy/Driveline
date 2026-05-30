//
//  LocationService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation
import Combine
import Observation

// MARK: - Location Service Status

enum LocationServiceStatus {
  case stopped, started, paused
}

// MARK: - Location Service

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

  // MARK: - Properties

  var status: LocationServiceStatus = .stopped

  @ObservationIgnored let locationPublisher = PassthroughSubject<CLLocation, Never>()
  @ObservationIgnored private let manager = CLLocationManager()

  // MARK: - Computed properties

  var activityType: CLActivityType { manager.activityType }

  // MARK: - Lifecycle

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    manager.activityType = activityTypeFromSettings()
    manager.pausesLocationUpdatesAutomatically = false
    manager.allowsBackgroundLocationUpdates = true
  }

  // MARK: - Actions

  func start() {
    guard status != .started else {
      Log.location.info("Monitoring locations already started; ignoring.")
      return
    }

    Log.location.info("Starting monitoring locations")

    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }

    manager.startUpdatingLocation()
    status = .started
    Log.location.info("Started monitoring locations")
  }

  func stop() {
    guard status != .stopped else {
      Log.location.info("Monitoring locations already stopped; ignoring.")
      return
    }

    Log.location.info("Stopping monitoring locations")
    manager.stopUpdatingLocation()
    status = .stopped
    Log.location.info("Stopped monitoring locations")
  }

  func pause() {
    guard status != .paused else {
      Log.location.info("Monitoring locations already paused; ignoring.")
      return
    }

    Log.location.info("Pausing monitoring locations")
    manager.stopUpdatingLocation()
    status = .paused
    Log.location.info("Paused monitoring locations")
  }

  func resume() {
    guard status != .started else {
      Log.location.info("Monitoring locations already resumed; ignoring.")
      return
    }

    Log.location.info("Resuming monitoring locations")
    manager.startUpdatingLocation()
    status = .started
    Log.location.info("Resumed monitoring locations")
  }

  // MARK: - CLLocationManagerDelegate callback functions

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    Task { @MainActor in
      Log.location.info("Did accept location - asking for background permissions")
      if self.manager.authorizationStatus == .authorizedWhenInUse {
        self.manager.requestAlwaysAuthorization()
      }
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    Task { @MainActor in
      Log.location.info("\(locations.count) new location(s) received")
      for location in locations {
        locationPublisher.send(location)
      }
    }
  }

  // MARK: - Private functions

  private func activityTypeFromSettings() -> CLActivityType {
    let rawValue = UserDefaults.standard.string(forKey: "ActivityType") ?? "automotive"
    let type = CLActivityType(fromSettings: rawValue)
    Log.location.info("Location activity type set to \"\(rawValue)\" from user settings")
    return type
  }
}
