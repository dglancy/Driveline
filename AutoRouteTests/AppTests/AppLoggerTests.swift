//
//  AppLoggerTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
@testable import AutoRoute

@Suite("AppLogger")
struct AppLoggerTests {

  // MARK: - Initialisation

  @Test func initialisesWithDefaultSubsystem() {
    _ = AppLogger(category: "Test")
  }

  @Test func initialisesWithCustomSubsystem() {
    _ = AppLogger(subsystem: "com.test.app", category: "Test")
  }

  // MARK: - Logging

  @Test func infoDoesNotCrash() {
    AppLogger(category: "Test").info("test info message")
  }

  @Test func debugDoesNotCrash() {
    AppLogger(category: "Test").debug("test debug message")
  }

  @Test func errorDoesNotCrash() {
    AppLogger(category: "Test").error("test error message")
  }

  // MARK: - Log Enum

  @Test func logEnumCategoriesAreAccessible() {
    _ = Log.lifecycle
    _ = Log.ui
    _ = Log.location
    _ = Log.data
    _ = Log.intent
  }
}
