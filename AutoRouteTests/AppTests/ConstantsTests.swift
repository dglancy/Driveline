//
//  ConstantsTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
@testable import AutoRoute

@Suite("Constants")
struct ConstantsTests {

  // MARK: - App

  @Test func appBundleIdHasCorrectPrefix() {
    #expect(kAppBundleId.hasPrefix("com.targatrips."))
  }

  @Test func gpxCreatorHasCorrectSuffix() {
    #expect(kGPXCreator.hasSuffix("for iOS"))
  }

  @Test func automotiveNavigationSpeedThresholdIsEight() {
    #expect(kAutomotiveNavigationSpeedRecordingThreshold == 8)
  }

  // MARK: - Testing

  @Test func uiTestingFlagValue() {
    #expect(kUITestingFlag == "-ui-testing")
  }
}
