//
//  Driveline.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftData
import SwiftUI

@main
struct Driveline: App {

  // MARK: - Properties

  @State private var driveService: DriveRecordingService
  @Environment(\.scenePhase) private var scenePhase

  private let modelContainer: ModelContainer

  // MARK: - Lifecycle

  init() {
    let env = AppBootstrap.boot()
    self.modelContainer = env.modelContainer
    _driveService = State(initialValue: env.driveService)
  }

  // MARK: - Main View Scene

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environment(driveService)
        .onChange(of: scenePhase) { _, newPhase in
          guard newPhase == .active else { return }
          Task { await driveService.checkAndRetryNilPlaceNamesForFinishedDrives() }
        }
    }
    .modelContainer(modelContainer)
  }
}
