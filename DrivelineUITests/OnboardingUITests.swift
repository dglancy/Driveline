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
}
