//
//  AppLoggerTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Testing

@Suite("AppLogger")
struct AppLoggerTests {

  // MARK: - Initialization

  @Test
  @MainActor
  func initializesWithDefaultSubsystem() {
    _ = AppLogger(category: "Test")
  }

  @Test
  @MainActor
  func initializesWithCustomSubsystem() {
    _ = AppLogger(category: "Test")
  }

  // MARK: - Logging

  @Test
  @MainActor
  func infoDoesNotCrash() {
    AppLogger(category: "Test").info("test info message")
  }

  @Test
  @MainActor
  func debugDoesNotCrash() {
    AppLogger(category: "Test").debug("test debug message")
  }

  @Test
  @MainActor
  func errorDoesNotCrash() {
    AppLogger(category: "Test").error("test error message")
  }

  // MARK: - Log Enum

  @Test
  @MainActor
  func logEnumCategoriesAreAccessible() {
    _ = Log.lifecycle
    _ = Log.ui
    _ = Log.location
    _ = Log.data
  }
}
