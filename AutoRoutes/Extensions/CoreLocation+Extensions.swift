//
//  CoreLocation+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation

// MARK: - ActivityTypeSetting

enum ActivityTypeSetting: String, CaseIterable {
  case automatic
  case automotive
  case fitness
  case other
  case flight

  // MARK: - Properties

  static let `default` = ActivityTypeSetting.automotive

  // MARK: - Computed Properties

  var activityType: CLActivityType {
    switch self {
    case .automatic, .automotive: return .automotiveNavigation
    case .fitness: return .fitness
    case .other: return .other
    case .flight: return .airborne
    }
  }
}

// MARK: - CLActivityType extension

extension CLActivityType {

  // MARK: - Lifecycle

  init(fromSettings value: String) {
    self = ActivityTypeSetting(rawValue: value)?.activityType ?? .otherNavigation
  }
}
