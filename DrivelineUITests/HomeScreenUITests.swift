//
//  HomeViewUITests.swift
//  Driveline
//
//  Created by Damien Glancy on 14/06/2026.
//

import XCTest

final class HomeScreenUITests: BaseXCTestCase {
  
  // MARK: - Tests
  
  @MainActor
  func testHomeScreen() throws {
    navigateToHomeScreen()

    XCTAssertTrue(app.buttons["NewDriveButton"].exists)
    XCTAssertTrue(app.buttons["More options"].exists)
    XCTAssertTrue(
      app.searchFields["Search"].exists || app.buttons["Search"].exists
    )
  }

  @MainActor
  func testSelectingDriveShowsDetailAndReturnsToList() throws {
    navigateToHomeScreen()

    app.buttons["Drive row 0"].tap()

    XCTAssertTrue(app.buttons["Edit Drive Details"].waitForExistence(timeout: 5))
    app.buttons["Back"].tap()
    XCTAssertTrue(app.navigationBars["Drives"].waitForExistence(timeout: 5))
  }

  @MainActor
  func testDriveDetailToolbarSurvivesWindowResize() throws {
    let originalOrientation = XCUIDevice.shared.orientation
    defer { XCUIDevice.shared.orientation = originalOrientation }

    XCUIDevice.shared.orientation = .portrait
    navigateToHomeScreen()

    app.buttons["Drive row 0"].tap()

    XCTAssertTrue(app.buttons["Edit Drive Details"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Full screen map"].exists)
    XCTAssertTrue(app.buttons["Delete Drive"].exists)

    XCUIDevice.shared.orientation = .landscapeLeft

    XCTAssertTrue(app.buttons["Edit Drive Details"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Full screen map"].exists)
    XCTAssertTrue(app.buttons["Delete Drive"].exists)
  }
  
  @MainActor
  func testMergeSheetShowsContentOnFirstPresentation() throws {
    navigateToHomeScreen()

    app.buttons["NewDriveButton"].tap()
    XCTAssertTrue(app.buttons["FinishDriveButton"].waitForExistence(timeout: 5))
    app.buttons["FinishDriveButton"].tap()

    app.buttons["More options"].tap()
    app.buttons["Select Drives"].tap()
    app.buttons["Drive row 0"].tap()
    app.buttons["Drive row 1"].tap()
    app.buttons["Merge"].tap()

    XCTAssertTrue(app.navigationBars["Merge Drives"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Order"].exists)
    XCTAssertTrue(app.textFields["Drive name"].exists)
  }

  @MainActor
  func testSearchNoResults() throws {
    navigateToHomeScreen()
    
    let searchField = activateSearch()
    searchField.tap()
    searchField.typeText("Nothing will be found")

    XCTAssertTrue(app.staticTexts["No Results for \u{201C}Nothing will be found\u{201D}"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Check the spelling or try a new search."].exists)
    
    XCTAssertTrue(app.buttons["Clear text"].exists)
    XCTAssertTrue(app.buttons["close"].exists)
  }

  // MARK: - Helpers

  @MainActor
  private func activateSearch() -> XCUIElement {
    let searchField = app.searchFields["Search"]
    guard !searchField.exists else { return searchField }

    let searchButton = app.buttons["Search"]
    XCTAssertTrue(searchButton.exists)
    searchButton.tap()
    XCTAssertTrue(searchField.waitForExistence(timeout: 5))
    return searchField
  }
  
}
