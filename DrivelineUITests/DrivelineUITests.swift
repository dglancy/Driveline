//
//  DrivelineUITests.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 30/05/2026.
//

import XCTest

final class DrivelineUITests: BaseXCTestCase {

  @MainActor
  func testExample() throws {
    app.launch()

    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // XCUIAutomation Documentation
    // https://developer.apple.com/documentation/xcuiautomation
  }

  @MainActor
  func testLaunchPerformance() throws {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
      app.launch()
    }
  }
}
