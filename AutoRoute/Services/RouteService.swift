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

  static let pauseTimeoutTaskIdentifier = "com.targatrips.AutoRoute.pause-timeout"

  private(set) var route: Route?
  private(set) var currentSpeedMs: Double?

  var isRecording: Bool { route?.isRecording ?? false }
  var isPaused: Bool { route?.isPaused ?? false }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let locationDataRecorder: LocationDataRecorderService
  @ObservationIgnored private let geocodingService: any GeocodingServiceProtocol
  @ObservationIgnored private let networkMonitorService: NetworkMonitorService
  @ObservationIgnored private var speedCancellable: AnyCancellable?
  @ObservationIgnored private var startGeocodeCancellable: AnyCancellable?
  @ObservationIgnored private var networkCancellable: AnyCancellable?
  @ObservationIgnored private var pauseTimeoutTimer: Timer?

  // MARK: - Lifecycle

  init(modelContext: ModelContext,
       locationService: LocationService,
       locationDataRecorder: LocationDataRecorderService,
       geocodingService: any GeocodingServiceProtocol = GeocodingService(),
       networkMonitorService: NetworkMonitorService = NetworkMonitorService(),
       initialRoute: Route? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.geocodingService = geocodingService
    self.networkMonitorService = networkMonitorService
    self.route = initialRoute

    networkCancellable = networkMonitorService.connectivityRestoredPublisher
      .sink { [weak self] in
        Task { [weak self] in
          guard let self else { return }
          await self.retryNilPlaceNamesOnConnectivity()
        }
      }
  }

  // MARK: - Actions

  func startRoute(trigger: Route.RecordingTrigger = .manual) throws {
    let route = Route(name: routeNameForCurrentTime(), trigger: trigger)
    self.route = route
    currentSpeedMs = nil

    do {
      try locationDataRecorder.startRecording(with: route)
    } catch {
      self.route = nil
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
          guard let self, let route = self.route else { return }
          route.startPlaceName = await self.geocodingService.reverseGeocode(location: location)
          self.saveModelContext()
        }
      }
  }

  func endRoute() {
    cancelPauseTimeout()
    speedCancellable = nil
    startGeocodeCancellable = nil
    locationService.stop()

    if let route {
      route.endedAt = Date()
      route.status = .finished
      locationDataRecorder.stopRecording()
      saveModelContext()

      if let last = route.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        Task { [weak self] in
          guard let self else { return }
          route.endPlaceName = await geocodingService.reverseGeocode(location: location)
          saveModelContext()
        }
      }
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

  func checkAndAutoFinishIfTimedOut() {
    guard isPaused,
          let route = route,
          let pauseStartedAt = route.pauseStartedAt,
          Date().timeIntervalSince(pauseStartedAt) >= kPauseTimeoutInterval else { return }
    endRoute()
  }

  func checkAndRetryNilPlaceNamesForFinishedRoutes() async {
    guard networkMonitorService.isConnected else { return }
    let cutoff = Date().addingTimeInterval(kRouteAgeCutoff)
    let finishedStatus = Route.RouteStatus.finished
    let descriptor = FetchDescriptor<Route>(
      predicate: #Predicate<Route> { route in
        route.startedAt >= cutoff && route.status == finishedStatus
      }
    )
    guard let candidates = try? modelContext.fetch(descriptor) else { return }
    let needsRetry = candidates.filter { $0.startPlaceName == nil || $0.endPlaceName == nil }
    guard !needsRetry.isEmpty else { return }
    for finishedRoute in needsRetry {
      if finishedRoute.startPlaceName == nil, let first = finishedRoute.orderedPositions.first {
        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        finishedRoute.startPlaceName = await geocodingService.reverseGeocode(location: location)
      }
      if finishedRoute.endPlaceName == nil, let last = finishedRoute.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        finishedRoute.endPlaceName = await geocodingService.reverseGeocode(location: location)
      }
      saveModelContext()
    }
  }

  // MARK: - Private

  private func retryNilPlaceNamesOnConnectivity() async {
    if let activeRoute = route, activeRoute.startPlaceName == nil,
       let first = activeRoute.orderedPositions.first {
      let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
      activeRoute.startPlaceName = await geocodingService.reverseGeocode(location: location)
      saveModelContext()
    }
    await checkAndRetryNilPlaceNamesForFinishedRoutes()
  }

  private func schedulePauseTimeout() {
    let request = BGAppRefreshTaskRequest(identifier: Self.pauseTimeoutTaskIdentifier)
    request.earliestBeginDate = Date().addingTimeInterval(kPauseTimeoutInterval)
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      Log.lifecycle.error("Failed to schedule pause timeout background task: \(error)")
    }

    pauseTimeoutTimer = Timer.scheduledTimer(withTimeInterval: kPauseTimeoutInterval, repeats: false) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.checkAndAutoFinishIfTimedOut()
      }
    }
  }

  private func cancelPauseTimeout() {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.pauseTimeoutTaskIdentifier)
    pauseTimeoutTimer?.invalidate()
    pauseTimeoutTimer = nil
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
    modelContext.safeSave(onFailure: { Log.ui.error("Failed to save model context: \($0.localizedDescription)") })
  }
}
