//
//  UserPreferences.swift
//  AutoRoute
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
    Log.settings.info("Location activity type set to \"\(rawValue)\" from user settings")
    return CLActivityType(fromSettings: rawValue)
  }

  var exportMapSize: CGSize {
    let rawValue = defaults.string(forKey: Keys.exportMapSize) ?? "high2"
    Log.settings.info("Export map size set to \"\(rawValue)\" from user settings")
    return MapSize.size(for: rawValue)
  }

  var alwaysUseLightMapAppearance: Bool {
    let value = defaults.bool(forKey: Keys.alwaysUseLightMapAppearance)
    Log.settings.info("Always use light map appearance set to \"\(value)\" from user settings")
    return value
  }

  var routeWidth: CGFloat {
    let rawValue = defaults.string(forKey: Keys.routeWidth) ?? "medium"
    Log.settings.info("Route width set to \"\(rawValue)\" from user settings")
    return (RouteWidth(from: rawValue) ?? .medium).width
  }
}

// MARK: - Keys

private extension UserPreferences {
  enum Keys {
    static let activityType = "ActivityType"
    static let exportMapSize = "ExportMapSize"
    static let alwaysUseLightMapAppearance = "AlwaysUseLightMapAppearance"
    static let routeWidth = "RouteWidth"
  }
}
