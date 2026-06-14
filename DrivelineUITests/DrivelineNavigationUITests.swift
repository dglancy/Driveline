//
//  DrivelineUITests.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 30/05/2026.
//

import XCTest

final class DrivelineNavigationUITests: BaseXCTestCase {
  
  @MainActor
  func testNoDrivesEmptyScreen() throws {
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
    
    XCTAssertTrue(app.staticTexts["No Drives"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Your recorded drives will appear here."].exists)
    
    XCTAssertTrue(app.buttons["NewDriveButton"].exists)
  }
  
  @MainActor
  func testShowRecordScreenFromEmptyScreen() throws {
    navigatePastEmptyState()
    app.buttons["FinishDriveButton"].tap()
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
  }
}
