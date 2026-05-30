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
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Route.self,
      Position.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting())
    
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  // MARK: - Lifecycle
  
  init() {
    Log.lifecycle.info("App starting")
    let isUITesting = Self.isUITesting()
    
    if isUITesting {
      Log.lifecycle.info("Running in UI Testing mode")
    }
    Log.lifecycle.info("App started")
  }
  
  // MARK: - Main View Scene
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(sharedModelContainer)
  }
  
  // MARK: - Private functions
  
  private static func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains("-ui-testing")
  }
}
