//
//  RouteService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import Foundation
import SwiftData
import Combine
import os.log

@MainActor
final class RouteService: ObservableObject {

  // MARK: - Properties

  @Published private(set) var route: Route?
  @Published private(set) var currentSpeedMs: Double?

  var isRecording: Bool { route?.isRecording ?? false }
  var isPaused: Bool { route?.isPaused ?? false }

  private let modelContext: ModelContext
  private let locationService: LocationService
  private let locationDataRecorder: LocationDataRecorderService
  private var speedCancellable: AnyCancellable?

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
      route.isRecording = false
      route.isPaused = false
      locationDataRecorder.stopRecording()
      saveModelContext()
    }

    currentSpeedMs = nil
  }

  func pauseRoute() {
    locationService.pause()
    route?.isPaused = true
    route?.pauseStartedAt = Date()
  }

  func resumeRoute() {
    if let route, let pauseStart = route.pauseStartedAt {
      route.pausedDurationSeconds += Date().timeIntervalSince(pauseStart)
      route.pauseStartedAt = nil
    }
    route?.isPaused = false
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
    case 5..<12: return "Morning Drive"
    case 12..<17: return "Afternoon Drive"
    case 17..<21: return "Evening Drive"
    default: return "Night Drive"
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
