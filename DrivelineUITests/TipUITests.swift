//
//  TipUITests.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 16/06/2026.
//

import XCTest

final class TipUITests: BaseXCTestCase {

  // MARK: - Lifecycle
  
  override func setUp() async throws {
    enableTips()
    try await super.setUp()
  }
  
  // MARK: - Tests

  @MainActor
  func testRecordButtonTipAppearsOnFirstLaunch() throws {
    XCTAssertTrue(app.staticTexts["Record a Drive"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Tap to start manually tracking a new journey."].exists)
  }

  @MainActor
  func testStatsPanelTipAppearsAfterThreeDrivesRecorded() throws {
    closeRecordButtonTip()
    navigatePastEmptyState()
    
    XCTAssertTrue(app.staticTexts["RecordingBanner"].waitForExistence(timeout: 5))
    app.buttons["FinishDriveButton"].tap()
    
    app.buttons["NewDriveButton"].tap()
    XCTAssertTrue(app.staticTexts["RecordingBanner"].waitForExistence(timeout: 5))
    app.buttons["FinishDriveButton"].tap()
    
    app.buttons["NewDriveButton"].tap()
    XCTAssertTrue(app.staticTexts["RecordingBanner"].waitForExistence(timeout: 5))
    app.buttons["FinishDriveButton"].tap()
    
    XCTAssertTrue(app.staticTexts["Switch Stats View"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Tap to toggle between the last 30 days and all time."].waitForExistence(timeout: 5))
  }

  @MainActor
  func testEditDriveTipAppearsOnDriveDetail() throws {
    closeRecordButtonTip()
    navigateToHomeScreen()

    app.buttons["Drive row 0"].tap()

    XCTAssertTrue(app.staticTexts["Edit Your Drive"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Tap the options button to edit the name and other details."].exists)
  }
  
  // MARK: - Private
  
  private func closeRecordButtonTip() {
    app.buttons["Close"].tap()
  }
}
