//
//  RouteService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import SwiftData
import Combine
import os.log

final class RouteService: ObservableObject {

  // MARK: - Properties

  @Published private(set) var route: Route?

  private let modelContext: ModelContext
  private let locationService: LocationService
  private let locationDataRecorder: LocationDataRecorderService

  // MARK: - Lifecycle

  init(modelContext: ModelContext, locationService: LocationService, locationDataRecorder: LocationDataRecorderService, initialRoute: Route? = nil) {
    self.modelContext = modelContext
    self.locationService = locationService
    self.locationDataRecorder = locationDataRecorder
    self.route = initialRoute
  }

  // MARK: - Actions

  func startRoute() {
    let route = Route(name: "A route")
    route.isRecording = true
    self.route = route

    locationDataRecorder.startRecording(with: route)
    locationService.start()
  }

  func endRoute() {
    locationService.stop()

    if let route {
      route.endedAt = Date()
      route.isRecording = false
      locationDataRecorder.stopRecording()
      saveModelContext()
    }
  }

  func pauseRoute() {
    locationService.pause()
  }

  func resumeRoute() {
    locationService.resume()
  }

  func loadRoute(_ route: Route) {
    self.route = route
    locationService.stop()
    locationDataRecorder.stopRecording()
  }

  // MARK: - Private

  private func saveModelContext() {
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context: \(error.localizedDescription)")
    }
  }
}
