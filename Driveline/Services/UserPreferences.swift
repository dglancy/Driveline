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
}

// MARK: - Keys

private extension UserPreferences {
  enum Keys {
    static let activityType = "ActivityType"
    static let exportMapSize = "ExportMapSize"
    static let alwaysUseLightMapAppearance = "AlwaysUseLightMapAppearance"
    static let driveWidth = "DriveWidth"
    static let continueDriveIfRecentlyFinished = "ContinueDriveIfRecentlyFinished"
  }
}
