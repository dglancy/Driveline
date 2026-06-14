//
//  RecordingScreenUITests.swift
//  Driveline
//
//  Created by Damien Glancy on 14/06/2026.
//

import XCTest

final class RecordingScreenUITests: BaseXCTestCase {
  
  @MainActor
  func testShowRecordScreen() throws {
    let beforeStart = Date.now
    navigatePastEmptyState()
    
    let recordingBanner = app.staticTexts["RecordingBanner"]
    XCTAssertTrue(recordingBanner.waitForExistence(timeout: 5))
    XCTAssertEqual(recordingBanner.label, "Recording in progress")
    let afterStart = Date.now
    
    XCTAssertEqual(app.staticTexts["Elapsed"].label, "Elapsed")
    XCTAssertEqual(app.staticTexts["ElapsedTime"].label, "Elapsed time")
    
    XCTAssertEqual(app.staticTexts["DistanceValue"].label, "0.0")
    let expectedDistanceUnit = Locale.current.measurementSystem == .metric ? "km" : "mi"
    XCTAssertEqual(app.staticTexts["DistanceUnit"].label, expectedDistanceUnit)
    
    XCTAssertTrue(app.staticTexts["PositionsCountValue"].exists)
    XCTAssertEqual(app.staticTexts["PositionCountLabel"].label, "logged")
    
    let expectedStartedAtValues = [beforeStart, afterStart].map {
      $0.formatted(.dateTime.hour().minute().locale(.current))
    }
    XCTAssertTrue(expectedStartedAtValues.contains(app.staticTexts["DriveStartedAtValue"].label))
    XCTAssertEqual(app.staticTexts["DriveStartedAtLabel"].label, "started")
    
    XCTAssertEqual(app.staticTexts["BatteryExplanation"].label, "Running in the background to save battery. Your full drive map appears here when the drive ends.")
    
    XCTAssertEqual(app.staticTexts["FinishDrive"].label, "Finish Drive")
    app.buttons["FinishDriveButton"].tap()
    
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
  }
}
