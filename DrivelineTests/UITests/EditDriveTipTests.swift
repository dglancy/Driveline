//
//  EditDriveTipTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

import Testing
@testable import Driveline

@Suite("EditDriveTip")
@MainActor
struct EditDriveTipTests {

  @Test
  func tipCanBeInstantiated() {
    _ = EditDriveTip()
  }
}
