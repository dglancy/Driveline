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

  @Test func automaticallyMergeSameDayDrivesDefaultsToFalse() {
    let prefs = makePreferences()
    #expect(prefs.automaticallyMergeSameDayDrives == false)
  }

  @Test func automaticallyMergeSameDayDrivesReadsStoredValue() {
    let suiteName = "com.targatrips.Driveline.test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.set(true, forKey: "AutomaticallyMergeSameDayDrives")
    let prefs = UserPreferences(defaults: defaults)
    #expect(prefs.automaticallyMergeSameDayDrives == true)
  }

  @Test func pendingAutomaticMergePersistsAndClears() {
    var prefs = makePreferences()
    let day = Date(timeIntervalSinceReferenceDate: 1000)
    let deadline = Date(timeIntervalSinceReferenceDate: 2800)

    prefs.setPendingAutomaticMerge(day: day, deadline: deadline)

    #expect(prefs.pendingAutomaticMerge == .init(day: day, deadline: deadline))
    prefs.clearPendingAutomaticMerge()
    #expect(prefs.pendingAutomaticMerge == nil)
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

  @Test func hasSeenWelcomeDefaultsToFalse() {
    let prefs = makePreferences()
    #expect(prefs.hasSeenWelcome == false)
  }

  @Test func setHasSeenWelcomePersistsTrue() {
    var prefs = makePreferences()
    prefs.setHasSeenWelcome(true)
    #expect(prefs.hasSeenWelcome == true)
  }

  @Test func setHasSeenWelcomeCanBeReset() {
    var prefs = makePreferences()
    prefs.setHasSeenWelcome(true)
    prefs.setHasSeenWelcome(false)
    #expect(prefs.hasSeenWelcome == false)
  }

  @Test func hasSeenAutomationSetupDefaultsToFalse() {
    let prefs = makePreferences()
    #expect(prefs.hasSeenAutomationSetup == false)
  }

  @Test func setHasSeenAutomationSetupPersistsTrue() {
    var prefs = makePreferences()
    prefs.setHasSeenAutomationSetup(true)
    #expect(prefs.hasSeenAutomationSetup == true)
  }

  @Test func setHasSeenAutomationSetupCanBeReset() {
    var prefs = makePreferences()
    prefs.setHasSeenAutomationSetup(true)
    prefs.setHasSeenAutomationSetup(false)
    #expect(prefs.hasSeenAutomationSetup == false)
  }
}
