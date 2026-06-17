//
//  UserPreferencesTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

@testable import Driveline
import Testing
import Foundation

@Suite("UserPreferences")
@MainActor
struct UserPreferencesTests {

  private func makePreferences() -> UserPreferences {
    let suiteName = "com.targatrips.Driveline.test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    return UserPreferences(defaults: defaults)
  }

  @Test func hasCompletedOnboardingDefaultsToFalse() {
    let prefs = makePreferences()
    #expect(prefs.hasCompletedOnboarding == false)
  }

  @Test func setHasCompletedOnboardingPersistsTrue() {
    var prefs = makePreferences()
    prefs.setHasCompletedOnboarding(true)
    #expect(prefs.hasCompletedOnboarding == true)
  }

  @Test func setHasCompletedOnboardingCanBeReset() {
    var prefs = makePreferences()
    prefs.setHasCompletedOnboarding(true)
    prefs.setHasCompletedOnboarding(false)
    #expect(prefs.hasCompletedOnboarding == false)
  }
}
