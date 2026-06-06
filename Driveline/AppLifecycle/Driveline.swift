//
//  Driveline.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI
import SwiftData

@main
struct Driveline: App {

  // MARK: - Properties

  @State private var driveService: DriveRecordingService
  @Environment(\.scenePhase) private var scenePhase

  private let modelContainer: ModelContainer

  // MARK: - Lifecycle

  init() {
    Log.lifecycle.info("App starting")
    let isUITesting = Self.isUITesting()

    let modelContainer = Self.createModelContainer(inMemoryOnly: isUITesting)
    let locationService = Self.setupLocationService()
    let locationDataRecorder = Self.setupLocationDataRecorderService(locationService: locationService,
                                                                     modelContext: modelContainer.mainContext)
    let networkMonitorService = NetworkMonitorService()
    let driveService = Self.setupDriveRecordingService(modelContext: modelContainer.mainContext,
                                              locationService: locationService,
                                              locationDataRecorder: locationDataRecorder,
                                              networkMonitorService: networkMonitorService)

    self.modelContainer = modelContainer
    _driveService = State(initialValue: driveService)

    Self.registerIntentDependencies(driveService: driveService)

    if isUITesting {
      Log.lifecycle.info("Running in UI Testing mode")
    }
    Log.lifecycle.info("App started")
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

  // MARK: - Setup

  private static func createModelContainer(inMemoryOnly: Bool) -> ModelContainer {
    Log.lifecycle.info("Setting up data model and container")
    let schema = Schema([
      Drive.self,
      Position.self
    ])

    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemoryOnly)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  private static func setupLocationService() -> LocationService {
    Log.lifecycle.info("Setting up location services")
    return LocationService()
  }

  private static func setupLocationDataRecorderService(
    locationService: LocationService,
    modelContext: ModelContext
  ) -> LocationDataRecorderService {
    Log.lifecycle.info("Setting up location data recorder")
    return LocationDataRecorderService(locationService: locationService, modelContext: modelContext)
  }

  private static func setupDriveRecordingService(
    modelContext: ModelContext,
    locationService: LocationService,
    locationDataRecorder: LocationDataRecorderService,
    networkMonitorService: any NetworkMonitorServiceProtocol
  ) -> DriveRecordingService {
    Log.lifecycle.info("Setting up drive service")
    var descriptor = FetchDescriptor<Drive>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
    descriptor.fetchLimit = 1
    let activeDrive = (try? modelContext.fetch(descriptor))?.first.flatMap { $0.status != .finished ? $0 : nil }
    return DriveRecordingService(modelContext: modelContext, locationService: locationService,
                        locationDataRecorder: locationDataRecorder,
                        networkMonitorService: networkMonitorService,
                        initialDrive: activeDrive)
  }

  // MARK: - App Intents

  private static func registerIntentDependencies(
    driveService: DriveRecordingService
  ) {
    Log.lifecycle.info("Registering dependencies for App Intents")
    IntentDependencyResolver.provider = { driveService }
  }

  // MARK: - Private functions

  private static func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains("-ui-testing")
  }
}
