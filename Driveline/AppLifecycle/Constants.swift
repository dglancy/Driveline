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
    /// Bump this whenever `DriveCategoryClassifier.mlmodel` is retrained and shipped, so the
    /// category prediction sweep reclassifies every finished drive exactly once against the
    /// new model.
    nonisolated static let driveCategoryModelVersion = 1
    
    nonisolated static let minimumLocationAccuracy: CLLocationAccuracy = 50
    nonisolated static let maxLocationAge: TimeInterval = 5
    nonisolated static let drivePlaceNameSweepCutoff: TimeInterval = -2_592_000 // 30 days
    nonisolated static let driveWeatherSweepCutoff: TimeInterval = -2_592_000 // 30 days
    nonisolated static let recentDriveCutoff: TimeInterval = -1800
    nonisolated static let placeNameSweepTaskIdentifier = "com.targatrips.Driveline.placename-sweep"
    nonisolated static let weatherSweepTaskIdentifier = "com.targatrips.Driveline.weather-sweep"
    nonisolated static let categoryPredictionSweepTaskIdentifier = "com.targatrips.Driveline.category-prediction-sweep"
  }
  
  enum Statistics {
    nonisolated static let highSpeedMetresPerSecond: CLLocationSpeed = 80 / 3.6
    nonisolated static let stoppedSpeedMetresPerSecond: CLLocationSpeed = 5 / 3.6
    nonisolated static let sustainedMinimumSeconds: TimeInterval = 10
    nonisolated static let metresPerSecondToKilometresPerHour = 3.6
  }

  enum Testing {
    nonisolated static let UITestingFlag = "-ui-testing"
    nonisolated static let TipTestingFlag = "-tip-testing"
  }
}
