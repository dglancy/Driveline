//
//  Constants.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation

enum Constants {
  enum App {
    nonisolated static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.targatrips.Driveline"
    nonisolated static let GPXCreator = "Driveline for iOS"
    nonisolated static let dashString = "—"
  }
  
  enum Configuration {
    nonisolated static let minimumLocationAccuracy: CLLocationAccuracy = 50
    nonisolated static let maxLocationAge: TimeInterval = 5
    nonisolated static let drivePlaceNameSweepCutoff: TimeInterval = -2_592_000 // 30 days
    nonisolated static let driveWeatherSweepCutoff: TimeInterval = -2_592_000 // 30 days
    nonisolated static let recentDriveCutoff: TimeInterval = -1800
    nonisolated static let placeNameSweepTaskIdentifier = "com.targatrips.driveline.placename-sweep"
    nonisolated static let weatherSweepTaskIdentifier = "com.targatrips.driveline.weather-sweep"
  }
  
  enum Testing {
    nonisolated static let UITestingFlag = "-ui-testing"
  }
}
