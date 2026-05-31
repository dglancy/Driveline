//
//  CoreLocation+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation

// MARK: - CLActivityType extension

extension CLActivityType {

  // MARK: - Lifecycle

  init(fromSettings value: String) {
    switch value {
    case "automatic", "automotive": self = .automotiveNavigation
    case "fitness": self = .fitness
    case "other": self = .other
    case "flight": self = .airborne
    default: self = .otherNavigation
    }
  }
}
