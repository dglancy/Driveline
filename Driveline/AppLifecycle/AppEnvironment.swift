//
//  AppEnvironment.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

import SwiftData

@MainActor
struct AppEnvironment {

  // MARK: - Properties

  let modelContainer: ModelContainer
  let driveService: DriveRecordingService
  let placeNameSweepService: PlaceNameSweepService
  let weatherSweepService: WeatherSweepService
  let categoryPredictionSweepService: CategoryPredictionSweepService
  let spotlightIndexingService: SpotlightIndexingService
  let metricKitService: MetricKitService
}
