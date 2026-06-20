//
//  EditDriveTipTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

import Testing
@testable import Driveline

@Suite("EditDriveTip", .serialized)
@MainActor
struct EditDriveTipTests {

  init() {
    EditDriveTip.isOnboardingPresented = true
  }

  @Test
  func tipCanBeInstantiated() {
    _ = EditDriveTip()
  }

  // MARK: - Rules

  @Test
  func gatesOnOnboardingDismissed() {
    #expect(EditDriveTip().rules.count == 1)
  }

  // MARK: - isOnboardingPresented parameter

  @Test
  func isOnboardingPresentedDefaultsToTrue() {
    #expect(EditDriveTip.isOnboardingPresented == true)
  }

  @Test
  func isOnboardingPresentedCanBeSetToFalse() {
    EditDriveTip.isOnboardingPresented = false
    defer { EditDriveTip.isOnboardingPresented = true }
    #expect(EditDriveTip.isOnboardingPresented == false)
  }
}
