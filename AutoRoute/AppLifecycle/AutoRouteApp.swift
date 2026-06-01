//
//  AutoRouteApp.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import BackgroundTasks
import SwiftUI
import SwiftData

@main
struct AutoRouteApp: App {

  // MARK: - Properties

  @State private var routeService: RouteService
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
    let routeService = Self.setupRouteService(modelContext: modelContainer.mainContext,
                                              locationService: locationService,
                                              locationDataRecorder: locationDataRecorder,
                                              networkMonitorService: networkMonitorService)

    self.modelContainer = modelContainer
    _routeService = State(initialValue: routeService)

    Self.registerIntentDependencies(routeService: routeService)
    Self.registerBGTasks(routeService: routeService)

    if isUITesting {
      Log.lifecycle.info("Running in UI Testing mode")
    }
    Log.lifecycle.info("App started")
  }

  // MARK: - Main View Scene

  var body: some Scene {
    WindowGroup {
      HomeView()
        .environment(routeService)
        .onChange(of: scenePhase) { _, newPhase in
          guard newPhase == .active else { return }
          routeService.checkAndAutoFinishIfTimedOut()
          Task { await routeService.checkAndRetryNilPlaceNamesForFinishedRoutes() }
        }
    }
    .modelContainer(modelContainer)
  }

  // MARK: - Factories

  private static func createModelContainer(inMemoryOnly: Bool) -> ModelContainer {
    Log.lifecycle.info("Setting up data model and container")
    let schema = Schema([
      Route.self,
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

  private static func setupRouteService(
    modelContext: ModelContext,
    locationService: LocationService,
    locationDataRecorder: LocationDataRecorderService,
    networkMonitorService: NetworkMonitorService
  ) -> RouteService {
    Log.lifecycle.info("Setting up route service")
    var descriptor = FetchDescriptor<Route>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
    descriptor.fetchLimit = 1
    let activeRoute = (try? modelContext.fetch(descriptor))?.first.flatMap { $0.status != .finished ? $0 : nil }
    return RouteService(modelContext: modelContext, locationService: locationService,
                        locationDataRecorder: locationDataRecorder,
                        networkMonitorService: networkMonitorService,
                        initialRoute: activeRoute)
  }

  // MARK: - Background Tasks

  private static func registerBGTasks(routeService: RouteService) {
    Log.lifecycle.info("Registering background tasks")
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: RouteService.pauseTimeoutTaskIdentifier,
      using: .main
    ) { task in
      task.expirationHandler = { task.setTaskCompleted(success: false) }
      Task { @MainActor in
        routeService.checkAndAutoFinishIfTimedOut()
        task.setTaskCompleted(success: true)
      }
    }
  }

  // MARK: - App Intents

  private static func registerIntentDependencies(
    routeService: RouteService
  ) {
    Log.lifecycle.info("Registering dependencies for App Intents")
    IntentDependencyResolver.provider = { routeService }
  }

  // MARK: - Private functions

  private static func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains("-ui-testing")
  }
}
