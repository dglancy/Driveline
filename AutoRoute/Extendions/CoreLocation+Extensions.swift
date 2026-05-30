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

  // MARK: - Computed properties

  var title: String {
    switch self {
    case .automotiveNavigation: return "Car"
    case .fitness: return "Person"
    case .airborne: return "Airplane"
    case .other: return "Other"
    case .otherNavigation: return "Bicycle"
    @unknown default: return "Other"
    }
  }

  var systemImageName: String {
    switch self {
    case .automotiveNavigation: return "car.fill"
    case .fitness: return "figure.walk"
    case .airborne: return "airplane"
    case .other: return "location.fill"
    case .otherNavigation: return "bicycle"
    @unknown default: return "location"
    }
  }

  // MARK: - Lifecycle

  init(fromSettings value: String) {
    switch value {
    case "automotive": self = .automotiveNavigation
    case "fitness": self = .fitness
    case "other": self = .other
    case "flight": self = .airborne
    default: self = .otherNavigation
    }
  }
}

// MARK: - CLocation extension

public extension CLLocation {
  var speedKilometersPerHour: Double {
    max(0, speed) * 3.6
  }
}
