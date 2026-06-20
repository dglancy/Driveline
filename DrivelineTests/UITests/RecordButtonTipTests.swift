//
//  RecordButtonTipTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

import Testing
@testable import Driveline

@Suite("RecordButtonTip")
@MainActor
struct RecordButtonTipTests {

  init() {
    RecordButtonTip.isOnboardingPresented = true
    RecordButtonTip.hasDrives = false
    RecordButtonTip.isRecording = false
  }

  // MARK: - Instantiation

  @Test
  func tipCanBeInstantiated() {
    _ = RecordButtonTip()
  }

  // MARK: - Rules

  @Test
  func gatesOnOnboardingDismissedAndHavingDrivesAndNotRecording() {
    #expect(RecordButtonTip().rules.count == 3)
  }

  // MARK: - Parameters

  @Test
  func hasDrivesDefaultsToFalse() {
    #expect(RecordButtonTip.hasDrives == false)
  }

  @Test
  func isOnboardingPresentedDefaultsToTrue() {
    #expect(RecordButtonTip.isOnboardingPresented == true)
  }

  // MARK: - isRecording parameter

  @Test
  func isRecordingDefaultsToFalse() {
    #expect(RecordButtonTip.isRecording == false)
  }

  @Test
  func isRecordingCanBeSetToTrue() {
    RecordButtonTip.isRecording = true
    defer { RecordButtonTip.isRecording = false }
    #expect(RecordButtonTip.isRecording == true)
  }
}
