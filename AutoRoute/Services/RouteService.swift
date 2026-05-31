//
//  RouteService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import BackgroundTasks
import CoreLocation
import Foundation
import Observation
import SwiftData
import Combine
import os.log

@MainActor
@Observable
final class RouteService {

  // MARK: - Properties

  static let pauseTimeoutInterval: TimeInterval = 3 * 3600
  static let pauseTimeoutTaskIdentifier = "com.targatrips.AutoRoute.pause-timeout"

  private(set) var route: Route?
  private(set) var currentSpeedMs: Double?

  var isRecording: Bool { route?.isRecording ?? false }
  var isPaused: Bool { route?.isPaused ?? false }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let locationDataRecorder: LocationDataRecorderService
  @ObservationIgnored private let geocodingService: GeocodingService
  @ObservationIgnored private var speedCancellable: AnyCancellable?
  @ObservationIgnored private var startGeocodeCancellable: AnyCancellable?

  // MARK: - Lifecycle

  init(modelContext: ModelContext,
       locationService: LocationService,
       locationDataRecorder: LocationDataRecorderService,
       geocodingService: GeocodingService = GeocodingService(),
       initialRoute: Route? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.geocodingService = geocodingService
    self.route = initialRoute
  }

  // MARK: - Actions

  func startRoute(trigger: Route.RecordingTrigger = .manual) {
    let route = Route(name: routeNameForCurrentTime(), trigger: trigger)
    self.route = route
    currentSpeedMs = nil

    locationDataRecorder.startRecording(with: route)
    locationService.start()

    speedCancellable = locationService.locationPublisher
      .sink { [weak self] location in
        self?.currentSpeedMs = location.speed >= 0 ? location.speed : nil
      }

    startGeocodeCancellable = locationService.locationPublisher
      .prefix(1)
      .sink { [weak self] location in
        guard let self else { return }
        Task { [weak self] in
          guard let self else { return }
          self.route?.startPlaceName = await self.geocodingService.reverseGeocode(location: location)
          self.saveModelContext()
        }
      }
  }

  func endRoute() async {
    cancelPauseTimeout()
    speedCancellable = nil
    startGeocodeCancellable = nil
    locationService.stop()

    if let route {
      route.endedAt = Date()
      route.status = .finished
      locationDataRecorder.stopRecording()

      if let last = route.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        route.endPlaceName = await geocodingService.reverseGeocode(location: location)
      }

      saveModelContext()
    }

    currentSpeedMs = nil
    self.route = nil
  }

  func pauseRoute() {
    locationService.pause()
    route?.status = .paused
    route?.pauseStartedAt = Date()
    schedulePauseTimeout()
  }

  func resumeRoute() {
    cancelPauseTimeout()
    if let route, let pauseStart = route.pauseStartedAt {
      route.pausedDurationSeconds += Date().timeIntervalSince(pauseStart)
      route.pauseStartedAt = nil
    }
    route?.status = .recording
    locationService.resume()
  }

  func checkAndAutoFinishIfTimedOut() async {
    guard isPaused,
          let pauseStartedAt = route?.pauseStartedAt,
          Date().timeIntervalSince(pauseStartedAt) >= Self.pauseTimeoutInterval else { return }
    await endRoute()
  }

  func loadRoute(_ route: Route) {
    self.route = route
    locationService.stop()
    locationDataRecorder.stopRecording()
  }

  // MARK: - Private

  private func schedulePauseTimeout() {
    let request = BGAppRefreshTaskRequest(identifier: Self.pauseTimeoutTaskIdentifier)
    request.earliestBeginDate = Date().addingTimeInterval(Self.pauseTimeoutInterval)
    try? BGTaskScheduler.shared.submit(request)
  }

  private func cancelPauseTimeout() {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.pauseTimeoutTaskIdentifier)
  }

  private func routeNameForCurrentTime() -> String {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12: return String(localized: "Morning Drive", comment: "Default route name for routes started between 05:00 and 11:59")
    case 12..<17: return String(localized: "Afternoon Drive", comment: "Default route name for routes started between 12:00 and 16:59")
    case 17..<21: return String(localized: "Evening Drive", comment: "Default route name for routes started between 17:00 and 20:59")
    default: return String(localized: "Night Drive", comment: "Default route name for routes started between 21:00 and 04:59")
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
