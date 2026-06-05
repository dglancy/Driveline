//
//  ConstantsTests.swift
//  AutoDriveTests
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
    #expect(kGPXCreator.hasSuffix("Driveline for iOS"))
  }

  // MARK: - Testing

  @Test
  func uiTestingFlagValue() {
    #expect(kUITestingFlag == "-ui-testing")
  }
}
