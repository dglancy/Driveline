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

  // MARK: - Lifecycle

  override func setUp() async throws {
    try await super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments += ["-ui-testing"]
    app.launch()
  }

  override func tearDown() async throws {
    app = nil
    try await super.tearDown()
  }
  
  // MARK: - Helper functions
  
  func navigatePastEmptyState() {
    app.buttons["Start a new drive"].tap()
  }
}
