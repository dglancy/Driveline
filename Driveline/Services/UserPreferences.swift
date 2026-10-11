//
//  UserPreferences.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import CoreLocation

// MARK: - UserPreferences

struct UserPreferences {

  struct PendingAutomaticMerge: Equatable, Sendable {
    let day: Date
    let deadline: Date
  }

  // MARK: - Properties

  private let defaults: UserDefaults

  // MARK: - Lifecycle

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  // MARK: - Computed Properties

  var activityType: CLActivityType {
    let rawValue = defaults.string(forKey: Keys.activityType) ?? ActivityTypeSetting.default.rawValue
    Log.settings.debug("Location activity type set to \"\(rawValue)\" from user settings")
    return CLActivityType(fromSettings: rawValue)
  }

  var exportMapSize: CGSize {
    let rawValue = defaults.string(forKey: Keys.exportMapSize) ?? "high2"
    Log.settings.debug("Export map size set to \"\(rawValue)\" from user settings")
    return (MapSize(from: rawValue) ?? .high2).size
  }

  var alwaysUseLightMapAppearance: Bool {
    let value = defaults.bool(forKey: Keys.alwaysUseLightMapAppearance)
    Log.settings.debug("Always use light map appearance set to \"\(value)\" from user settings")
    return value
  }

  var driveWidth: CGFloat {
    let rawValue = defaults.string(forKey: Keys.driveWidth) ?? "medium"
    Log.settings.debug("Drive width set to \"\(rawValue)\" from user settings")
    return (DriveWidth(from: rawValue) ?? .medium).width
  }

  var continueDriveIfRecentlyFinished: Bool {
    let value = defaults.bool(forKey: Keys.continueDriveIfRecentlyFinished)
    Log.settings.debug("Continue drive if recently finished set to \"\(value)\" from user settings")
    return value
  }

  var automaticallyMergeSameDayDrives: Bool {
    let value = defaults.bool(forKey: Keys.automaticallyMergeSameDayDrives)
    Log.settings.debug("Automatically merge same-day drives set to \"\(value)\" from user settings")
    return value
  }

  var pendingAutomaticMerge: PendingAutomaticMerge? {
    guard let day = defaults.object(forKey: Keys.pendingAutomaticMergeDay) as? Date,
          let deadline = defaults.object(forKey: Keys.pendingAutomaticMergeDeadline) as? Date else {
      return nil
    }
    return PendingAutomaticMerge(day: day, deadline: deadline)
  }

  mutating func setPendingAutomaticMerge(day: Date, deadline: Date) {
    defaults.set(day, forKey: Keys.pendingAutomaticMergeDay)
    defaults.set(deadline, forKey: Keys.pendingAutomaticMergeDeadline)
  }

  mutating func clearPendingAutomaticMerge() {
    defaults.removeObject(forKey: Keys.pendingAutomaticMergeDay)
    defaults.removeObject(forKey: Keys.pendingAutomaticMergeDeadline)
  }

  var hasCompletedOnboarding: Bool {
    defaults.bool(forKey: Keys.hasCompletedOnboarding)
  }

  mutating func setHasCompletedOnboarding(_ value: Bool) {
    defaults.set(value, forKey: Keys.hasCompletedOnboarding)
  }

  var hasSeenWelcome: Bool {
    defaults.bool(forKey: Keys.hasSeenWelcome)
  }

  mutating func setHasSeenWelcome(_ value: Bool) {
    defaults.set(value, forKey: Keys.hasSeenWelcome)
  }

  var hasSeenAutomationSetup: Bool {
    defaults.bool(forKey: Keys.hasSeenAutomationSetup)
  }

  mutating func setHasSeenAutomationSetup(_ value: Bool) {
    defaults.set(value, forKey: Keys.hasSeenAutomationSetup)
  }
}

// MARK: - Keys

private extension UserPreferences {
  enum Keys {
    static let activityType = "ActivityType"
    static let exportMapSize = "ExportMapSize"
    static let alwaysUseLightMapAppearance = "AlwaysUseLightMapAppearance"
    static let driveWidth = "DriveWidth"
    static let continueDriveIfRecentlyFinished = "ContinueDriveIfRecentlyFinished"
    static let automaticallyMergeSameDayDrives = "AutomaticallyMergeSameDayDrives"
    static let pendingAutomaticMergeDay = "PendingAutomaticMergeDay"
    static let pendingAutomaticMergeDeadline = "PendingAutomaticMergeDeadline"
    static let hasCompletedOnboarding = "HasCompletedOnboarding"
    static let hasSeenWelcome = "HasSeenWelcome"
    static let hasSeenAutomationSetup = "HasSeenAutomationSetup"
  }
}
