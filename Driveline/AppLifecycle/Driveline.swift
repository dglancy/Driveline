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
  @State private var sweepService: PlaceNameSweepService
  @Environment(\.scenePhase) private var scenePhase

  private let modelContainer: ModelContainer

  // MARK: - Lifecycle

  init() {
    let env = AppBootstrap.boot()
    self.modelContainer = env.modelContainer
    _driveService = State(initialValue: env.driveService)
    _sweepService = State(initialValue: env.sweepService)
  }

  // MARK: - Main View Scene

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environment(driveService)
        .onChange(of: scenePhase) { _, newPhase in
          switch newPhase {
          case .active:
            Task { await sweepService.sweep() }
          case .background:
            schedulePlaceNameSweepTask()
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
    let request = BGProcessingTaskRequest(identifier: kPlaceNameSweepTaskIdentifier)
    request.requiresNetworkConnectivity = true
    try? BGTaskScheduler.shared.submit(request)
  }
}
