//
//  DrivelineUITests.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 30/05/2026.
//

import XCTest

final class DrivelineUITests: BaseXCTestCase {
  
  @MainActor
  func testNoDrivesEmptyScreen() throws {
    // Navigation title
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
    
    // Empty state
    XCTAssertTrue(app.staticTexts["No Drives"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Your recorded drives will appear here."].exists)
    
    // Record button
    XCTAssertTrue(app.buttons["Start a new drive"].exists)
  }
  
//  @MainActor
//  func testRecordScreenFromEmptyScreen() throws {
//    navigatePastEmptyState()
//    
//    let recordingBanner = app.staticTexts["RecordingBanner"]
//    XCTAssertTrue(recordingBanner.waitForExistence(timeout: 5))
//    XCTAssertEqual(recordingBanner.label, "Recording in progress")
//    
//    XCTAssertEqual(app.staticTexts["Elapsed"].label, "Elapsed")
//    
//    app.buttons["stop.fill"].firstMatch.tap()
//  }
}
