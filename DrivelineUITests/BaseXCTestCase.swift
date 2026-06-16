//
//  BaseXCTestCase.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 30/05/2026.
//

import XCTest

@MainActor
class BaseXCTestCase: XCTestCase {

  // MARK: - Properties

  var app: XCUIApplication!
  var extraLaunchArguments: [String] = []
  
  // MARK: - Lifecycle

  override func setUp() async throws {
    try await super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments += ["-ui-testing"] + extraLaunchArguments

    addUIInterruptionMonitor(withDescription: "System permission alert") { alert in
      for label in ["Allow While Using App", "Allow Once", "Allow"] where alert.buttons[label].exists {
        alert.buttons[label].tap()
        return true
      }
      return false
    }

    app.launch()
  }

  override func tearDown() async throws {
    app = nil
    try await super.tearDown()
  }
  
  // MARK: - Navigation functions
  
  func navigatePastEmptyState() {
    app.buttons["NewDriveButton"].tap()

    // Starting a drive may trigger a location permission alert; tapping the
    // app flushes the interruption monitor registered in setUp() so it can
    // dismiss the alert before we assert on the recording screen.
    app.tap()
  }
  
  func navigateToHomeScreen() {
    navigatePastEmptyState()
    app.buttons["FinishDriveButton"].tap()
  }
  
  // MARK: - Options functions
  
  func enableTips() {
    extraLaunchArguments = ["-tip-testing"]
  }
}
