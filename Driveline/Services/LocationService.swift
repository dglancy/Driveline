//
//  LocationService.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation
import Combine
import Observation

// MARK: - Location Service

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {

  // MARK: - Types

  enum LocationServiceStatus {
    case stopped, started
  }

  // MARK: - Properties

  var status: LocationServiceStatus = .stopped

  @ObservationIgnored let locationPublisher = PassthroughSubject<CLLocation, Never>()
  @ObservationIgnored private let manager = CLLocationManager()
  @ObservationIgnored private var alwaysAuthorizationRequested = false
  @ObservationIgnored private let streamProvider: any LocationStreaming
  @ObservationIgnored private let sessionProvider: any BackgroundActivitySessionProviding
  @ObservationIgnored private var streamTask: Task<Void, Never>?
  @ObservationIgnored private var backgroundSession: (any BackgroundActivitySession)?

  // MARK: - Lifecycle

  init(
    preferences: UserPreferences = UserPreferences(),
    streamProvider: (any LocationStreaming)? = nil,
    sessionProvider: any BackgroundActivitySessionProviding = SystemBackgroundActivitySessionProvider()
  ) {
    self.streamProvider = streamProvider ?? LiveLocationStreamProvider(configuration: preferences.activityType.liveConfiguration)
    self.sessionProvider = sessionProvider
    super.init()
    manager.delegate = self
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

    backgroundSession = sessionProvider.begin()
    status = .started

    streamTask = Task { @MainActor [weak self] in
      guard let self else { return }
      Log.location.info("Stream task started; awaiting locations")
      for await location in self.streamProvider.locations() {
        Log.location.info("Stream task received a location")
        guard self.isUsable(location) else {
          Log.location.info("Location was not usable")
          continue
        }
        Log.location.info("Publishing location")
        self.locationPublisher.send(location)
      }
      Log.location.info("Stream task ended")
    }

    Log.location.info("Started monitoring locations")
  }

  func stop() {
    guard status != .stopped else {
      Log.location.info("Monitoring locations already stopped; ignoring.")
      return
    }

    Log.location.info("Stopping monitoring locations")
    streamTask?.cancel()
    streamTask = nil
    backgroundSession?.invalidate()
    backgroundSession = nil
    status = .stopped
    Log.location.info("Stopped monitoring locations")
  }

  nonisolated func isUsable(_ location: CLLocation) -> Bool {
    location.horizontalAccuracy >= 0 &&
    location.horizontalAccuracy < Constants.Configuration.minimumLocationAccuracy &&
    -location.timestamp.timeIntervalSinceNow < Constants.Configuration.maxLocationAge
  }

  // MARK: - CLLocationManagerDelegate callback functions

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    Task { @MainActor in
      Log.location.info("Location authorisation changed to \(status.rawValue)")
      guard self.status == .started,
            status == .authorizedWhenInUse,
            !self.alwaysAuthorizationRequested else { return }
      self.alwaysAuthorizationRequested = true
      self.manager.requestAlwaysAuthorization()
    }
  }
}
