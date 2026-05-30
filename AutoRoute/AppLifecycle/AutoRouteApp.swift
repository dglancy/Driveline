//
//  AutoRouteApp.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI
import SwiftData

@main
struct AutoRouteApp: App {

  // MARK: - Properties

  @State private var routeService: RouteService

  private let locationService: LocationService
  private let locationDataRecorderService: LocationDataRecorderService
  private let modelContainer: ModelContainer

  // MARK: - Lifecycle

  init() {
    Log.lifecycle.info("App starting")
    let isUITesting = Self.isUITesting()

    modelContainer = Self.createModelContainer(isUITesting: isUITesting)
    locationService = Self.setupLocationService()
    locationDataRecorderService = Self.setupLocationDataRecorderService(locationService: locationService, modelContext: modelContainer.mainContext)

    let routeService = Self.setupRouteService(modelContext: modelContainer.mainContext, locationService: locationService,
                                             locationDataRecorder: locationDataRecorderService)
    _routeService = State(initialValue: routeService)

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
    }
    .modelContainer(modelContainer)
  }

  // MARK: - Factories

  private static func createModelContainer(isUITesting: Bool) -> ModelContainer {
    Log.lifecycle.info("Setting up data model and container")
    let schema = Schema([
      Route.self,
      Position.self
    ])

    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

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
    locationDataRecorder: LocationDataRecorderService
  ) -> RouteService {
    Log.lifecycle.info("Setting up route service")
    return RouteService(modelContext: modelContext, locationService: locationService, locationDataRecorder: locationDataRecorder)
  }

  // MARK: - Private functions

  private static func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains("-ui-testing")
  }
}
