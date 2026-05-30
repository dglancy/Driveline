//
//  BaseXCTestCase.swift
//  AutoRouteUITests
//
//  Created by Damien Glancy on 30/05/2026.
//

import XCTest

class BaseXCTestCase: XCTestCase {

  // MARK: - Properties

  var app: XCUIApplication!

  // MARK: - Lifecycle

  override func setUpWithError() throws {
    try super.setUpWithError()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launchArguments += ["-ui-testing"]
  }

  override func tearDownWithError() throws {
    app = nil
    try super.tearDownWithError()
  }
}
