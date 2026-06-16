//
//  HomeViewUITests.swift
//  Driveline
//
//  Created by Damien Glancy on 14/06/2026.
//

import XCTest

final class HomeScreenUITests: BaseXCTestCase {
  
  @MainActor
  func testHomeScreen() throws {
    navigateToHomeScreen()
  }
  
  @MainActor
  func testRecordButtonTipAppearsOnFirstLaunch() throws {
    XCTAssertTrue(app.staticTexts["Record a Drive"].waitForExistence(timeout: 3))
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
