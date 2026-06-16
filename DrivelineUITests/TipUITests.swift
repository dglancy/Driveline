//
//  TipUITests.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 16/06/2026.
//

import XCTest

final class TipUITests: BaseXCTestCase {

  override var extraLaunchArguments: [String] { ["-tip-testing"] }

  @MainActor
  func testRecordButtonTipAppearsOnFirstLaunch() throws {
    XCTAssertTrue(app.staticTexts["Record a Drive"].waitForExistence(timeout: 3))
  }

//  @MainActor
//  func testStatsPanelTipAppearsOnFirstLaunch() throws {
//    navigateToHomeScreen()
//    XCTAssertTrue(app.staticTexts["Switch Stats View"].waitForExistence(timeout: 3))
//  }
}
