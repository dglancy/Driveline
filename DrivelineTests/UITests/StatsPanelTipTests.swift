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

  // MARK: - driveCount parameter

  @Test
  func driveCountDefaultsToZero() {
    StatsPanelTip.driveCount = 0
    #expect(StatsPanelTip.driveCount == 0)
  }

  @Test
  func driveCountCanBeSet() {
    StatsPanelTip.driveCount = 5
    defer { StatsPanelTip.driveCount = 0 }
    #expect(StatsPanelTip.driveCount == 5)
  }

  // MARK: - isRecording parameter

  @Test
  func isRecordingDefaultsToFalse() {
    StatsPanelTip.isRecording = false
    #expect(StatsPanelTip.isRecording == false)
  }

  @Test
  func isRecordingCanBeSetToTrue() {
    StatsPanelTip.isRecording = true
    defer { StatsPanelTip.isRecording = false }
    #expect(StatsPanelTip.isRecording == true)
  }
}
