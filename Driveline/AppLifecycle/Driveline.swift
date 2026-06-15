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
  @State private var categoryPredictionSweepService: CategoryPredictionSweepService
  @State private var spotlightIndexingService: SpotlightIndexingService
  @State private var metricKitService: MetricKitService
  @Environment(\.scenePhase) private var scenePhase

  private let modelContainer: ModelContainer

  private var sweepServices: [any SweepServiceProtocol] {
    [placeNameSweepService, weatherSweepService, categoryPredictionSweepService]
  }

  // MARK: - Lifecycle

  init() {
    let env = AppBootstrap.boot()
    self.modelContainer = env.modelContainer
    _driveService = State(initialValue: env.driveService)
    _placeNameSweepService = State(initialValue: env.placeNameSweepService)
    _weatherSweepService = State(initialValue: env.weatherSweepService)
    _categoryPredictionSweepService = State(initialValue: env.categoryPredictionSweepService)
    _spotlightIndexingService = State(initialValue: env.spotlightIndexingService)
    _metricKitService = State(initialValue: env.metricKitService)
  }

  // MARK: - Main View Scene

  var body: some Scene {
    WindowGroup {
      HomeView(spotlightIndexingService: spotlightIndexingService, modelContext: modelContainer.mainContext)
        .environment(driveService)
        .onChange(of: scenePhase) {
          switch scenePhase {
          case .active:
            sweepServices.forEach { service in Task { await service.sweep() } }
          case .background:
            sweepServices.forEach { scheduleSweepTask(for: $0) }
          default:
            break
          }
        }
    }
    .modelContainer(modelContainer)
  }

  // MARK: - Private

  private func scheduleSweepTask(for service: any SweepServiceProtocol) {
    let request = BGProcessingTaskRequest(identifier: service.taskIdentifier)
    request.requiresNetworkConnectivity = true
    try? BGTaskScheduler.shared.submit(request)
  }
}
