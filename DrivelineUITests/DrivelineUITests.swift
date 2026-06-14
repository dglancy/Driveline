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
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
    
    XCTAssertTrue(app.staticTexts["No Drives"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Your recorded drives will appear here."].exists)
    
    XCTAssertTrue(app.buttons["NewDriveButton"].exists)
  }
  
  @MainActor
  func testRecordScreenFromEmptyScreen() throws {
    navigatePastEmptyState()
    
    let recordingBanner = app.staticTexts["RecordingBanner"]
    XCTAssertTrue(recordingBanner.waitForExistence(timeout: 5))
    XCTAssertEqual(recordingBanner.label, "Recording in progress")
    
    XCTAssertEqual(app.staticTexts["Elapsed"].label, "Elapsed")
    XCTAssertEqual(app.staticTexts["ElapsedTime"].label, "Elapsed time")
    
    XCTAssertEqual(app.staticTexts["DistanceValue"].label, "0.0")
    XCTAssertEqual(app.staticTexts["DistanceUnit"].label, "km")
    
    XCTAssertEqual(app.staticTexts["PositionsCountValue"].label, "0")
    XCTAssertEqual(app.staticTexts["PositionCountLabel"].label, "logged")
    
    XCTAssertEqual(app.staticTexts["DriveStartedAtValue"].label, Date.now.formatted(.dateTime.hour().minute().locale(.current)))
    XCTAssertEqual(app.staticTexts["DriveStartedAtLabel"].label, "started")
    
    XCTAssertEqual(app.staticTexts["BatteryExplanation"].label, "Running in the background to save battery. Your full drive map appears here when the drive ends.")

    XCTAssertEqual(app.staticTexts["FinishDrive"].label, "Finish Drive")
    app.buttons["FinishDriveButton"].tap()
    
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
  }
  
  @MainActor
  func testHomeScreen() throws {
    navigateToHomeScreen()
  }
  
  @MainActor
  func testSearchNoResults() throws {
    navigateToHomeScreen()
    
    let searchField = app.searchFields["Search"]
    XCTAssertTrue(searchField.exists)
    searchField.tap()
    searchField.typeText("Nothing will be found")

    XCTAssertTrue(app.staticTexts["No Results for \u{201C}Nothing will be found\u{201D}"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Check the spelling or try a new search."].exists)
    
    XCTAssertTrue(app.buttons["Clear text"].exists)
    XCTAssertTrue(app.buttons["close"].exists)    
  }
}
