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
  }

  @Test
  func tipCanBeInstantiated() {
    _ = RecordButtonTip()
  }

  // MARK: - isOnboardingPresented parameter

  @Test
  func isOnboardingPresentedDefaultsToTrue() {
    #expect(RecordButtonTip.isOnboardingPresented == true)
  }

  @Test
  func isOnboardingPresentedCanBeSetToFalse() {
    RecordButtonTip.isOnboardingPresented = false
    defer { RecordButtonTip.isOnboardingPresented = true }
    #expect(RecordButtonTip.isOnboardingPresented == false)
  }
}
