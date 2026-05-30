//
//  RouteService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

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

  private(set) var route: Route?
  private(set) var currentSpeedMs: Double?

  var isRecording: Bool { route?.isRecording ?? false }
  var isPaused: Bool { route?.isPaused ?? false }

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let locationService: LocationService
  @ObservationIgnored private let locationDataRecorder: LocationDataRecorderService
  @ObservationIgnored private var speedCancellable: AnyCancellable?

  // MARK: - Lifecycle

  init(modelContext: ModelContext, locationService: LocationService, locationDataRecorder: LocationDataRecorderService, initialRoute: Route? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.route = initialRoute
  }

  // MARK: - Actions

  func startRoute() {
    let route = Route(name: routeNameForCurrentTime())
    self.route = route
    currentSpeedMs = nil

    locationDataRecorder.startRecording(with: route)
    locationService.start()

    speedCancellable = locationService.locationPublisher
      .sink { [weak self] location in
        self?.currentSpeedMs = location.speed >= 0 ? location.speed : nil
      }
  }

  func endRoute() {
    speedCancellable = nil
    locationService.stop()

    if let route {
      route.endedAt = Date()
      route.status = .finished
      locationDataRecorder.stopRecording()
      saveModelContext()
    }

    currentSpeedMs = nil
    self.route = nil
  }

  func pauseRoute() {
    locationService.pause()
    route?.status = .paused
    route?.pauseStartedAt = Date()
  }

  func resumeRoute() {
    if let route, let pauseStart = route.pauseStartedAt {
      route.pausedDurationSeconds += Date().timeIntervalSince(pauseStart)
      route.pauseStartedAt = nil
    }
    route?.status = .recording
    locationService.resume()
  }

  func loadRoute(_ route: Route) {
    self.route = route
    locationService.stop()
    locationDataRecorder.stopRecording()
  }

  // MARK: - Private

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
