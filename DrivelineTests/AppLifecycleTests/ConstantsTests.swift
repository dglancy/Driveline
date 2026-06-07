//
//  ConstantsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Testing

@Suite("Constants")
struct ConstantsTests {

  // MARK: - App

  @Test
  func gpxCreatorHasCorrectSuffix() {
    #expect(Constants.App.GPXCreator.hasSuffix("Driveline for iOS"))
  }

  // MARK: - Testing

  @Test
  func uiTestingFlagValue() {
    #expect(Constants.Testing.UITestingFlag == "-ui-testing")
  }
}
