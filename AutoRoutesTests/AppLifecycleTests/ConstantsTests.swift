//
//  ConstantsTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
import Testing

@Suite("Constants")
struct ConstantsTests {

  // MARK: - App

  @Test
  func appBundleIdHasCorrectPrefix() {
    #expect(kAppBundleId.hasPrefix("com.targatrips.AutoRoute"))
  }

  @Test
  func gpxCreatorHasCorrectSuffix() {
    #expect(kGPXCreator.hasSuffix("AutoRoute for iOS"))
  }

  // MARK: - Testing

  @Test
  func uiTestingFlagValue() {
    #expect(kUITestingFlag == "-ui-testing")
  }
}
