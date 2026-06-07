//
//  Driveline.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import BackgroundTasks
import SwiftData
import SwiftUI

@main
struct Driveline: App {

  // MARK: - Properties

  @State private var driveService: DriveRecordingService
  @State private var placeNameSweepService: PlaceNameSweepService
  @State private var weatherSweepService: WeatherSweepService
  @State private var spotlightIndexingService: SpotlightIndexingService
  @Environment(\.scenePhase) private var scenePhase

  private let modelContainer: ModelContainer

  // MARK: - Lifecycle

  init() {
    let env = AppBootstrap.boot()
    self.modelContainer = env.modelContainer
    _driveService = State(initialValue: env.driveService)
    _placeNameSweepService = State(initialValue: env.placeNameSweepService)
    _weatherSweepService = State(initialValue: env.weatherSweepService)
    _spotlightIndexingService = State(initialValue: env.spotlightIndexingService)
  }

  // MARK: - Main View Scene

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environment(driveService)
        .onChange(of: scenePhase) { _, newPhase in
          switch newPhase {
          case .active:
            Task { await placeNameSweepService.sweep() }
            Task { await weatherSweepService.sweep() }
            Task { await spotlightIndexingService.reindexAll() }
          case .background:
            schedulePlaceNameSweepTask()
            scheduleWeatherSweepTask()
          default:
            break
          }
        }
        .onOpenURL { url in
          guard url.scheme == "driveline", url.host == "finish" else { return }
          driveService.finishDrive()
        }
    }
    .modelContainer(modelContainer)
  }

  // MARK: - Private

  private func schedulePlaceNameSweepTask() {
    let request = BGProcessingTaskRequest(identifier: Constants.Configuration.placeNameSweepTaskIdentifier)
    request.requiresNetworkConnectivity = true
    try? BGTaskScheduler.shared.submit(request)
  }

  private func scheduleWeatherSweepTask() {
    let request = BGProcessingTaskRequest(identifier: Constants.Configuration.weatherSweepTaskIdentifier)
    request.requiresNetworkConnectivity = true
    try? BGTaskScheduler.shared.submit(request)
  }
}
