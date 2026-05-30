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

  private let modelContainer: ModelContainer

  // MARK: - Lifecycle

  init() {
    Log.lifecycle.info("App starting")
    let isUITesting = Self.isUITesting()

    modelContainer = Self.createModelContainer(isUITesting: isUITesting)

    if isUITesting {
      Log.lifecycle.info("Running in UI Testing mode")
    }
    Log.lifecycle.info("App started")
  }

  // MARK: - Main View Scene

  var body: some Scene {
    WindowGroup {
      HomeView()
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

  // MARK: - Private functions

  private static func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains("-ui-testing")
  }
}
