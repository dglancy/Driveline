//
//  StatsPanelTipTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

import Testing
@testable import Driveline

@Suite("StatsPanelTip")
@MainActor
struct StatsPanelTipTests {

  // MARK: - hasDrives parameter

  @Test
  func hasDrivesDefaultsToFalse() {
    StatsPanelTip.hasDrives = false
    #expect(StatsPanelTip.hasDrives == false)
  }

  @Test
  func hasDrivesCanBeSetToTrue() {
    StatsPanelTip.hasDrives = true
    defer { StatsPanelTip.hasDrives = false }
    #expect(StatsPanelTip.hasDrives == true)
  }
}
