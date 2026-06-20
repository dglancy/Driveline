//
//  OnboardingUITests.swift
//  DrivelineUITests
//
//  Created by Damien Glancy on 17/06/2026.
//

import XCTest

@MainActor
final class OnboardingUITests: BaseXCTestCase {

  override func setUp() async throws {
    enableOnboarding()
    try await super.setUp()
  }

  func testOnboardingWelcomeScreenIsPresented() {
    XCTAssertTrue(app.staticTexts["Welcome to Driveline"].waitForExistence(timeout: 3))
  }

  func testWelcomeGetStartedDismissesOnboarding() {
    XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 3))
    app.buttons["Get Started"].tap()
    XCTAssertFalse(app.staticTexts["Welcome to Driveline"].exists)
  }

  func testAutomationSetupPanelAppearsAfterFirstDrive() {
    app.buttons["Get Started"].tap()
    navigateToHomeScreen()
    XCTAssertTrue(app.staticTexts["Set Up Automated Recording"].waitForExistence(timeout: 3))
  }
}
