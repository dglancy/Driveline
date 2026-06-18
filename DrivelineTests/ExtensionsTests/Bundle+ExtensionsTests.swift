//
//  Bundle+ExtensionsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 18/06/2026.
//

import Foundation
import Testing

@testable import Driveline

@Suite
struct BundleExtensionsTests {

  // MARK: - iconFileName

  @Test("iconFileName returns nil for a bundle without CFBundleIcons")
  func testIconFileNameNilForTestBundle() {
    #expect(Bundle(for: NSObject.self).iconFileName == nil)
  }

  @Test("iconFileName returns a non-nil string for the app bundle")
  func testIconFileNameForAppBundle() {
    #expect(Bundle.main.iconFileName != nil)
  }
}
