//
//  BaseXCTestCase.swift
//  AutoDriveUITests
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
    app.launchArguments += [kUITestingFlag]
  }

  override func tearDown() async throws {
    app = nil
    try await super.tearDown()
  }
}
