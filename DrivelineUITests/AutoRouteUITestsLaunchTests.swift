//
//  AutoDriveUITestsLaunchTests.swift
//  AutoDriveUITests
//
//  Created by Damien Glancy on 30/05/2026.
//

import XCTest

final class AutoDriveUITestsLaunchTests: BaseXCTestCase {

  override class var runsForEachTargetApplicationUIConfiguration: Bool {
    true
  }

  @MainActor
  func testLaunch() throws {
    app.launch()

    // Insert steps here to perform after app launch but before taking a screenshot,
    // such as logging into a test account or navigating somewhere in the app
    // XCUIAutomation Documentation
    // https://developer.apple.com/documentation/xcuiautomation

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
