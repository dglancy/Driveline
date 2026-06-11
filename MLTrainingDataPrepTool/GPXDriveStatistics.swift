//
//  GPXDriveStatistics.swift
//  MLTrainingDataPrepTool
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation

// MARK: - GPX drive statistics

struct GPXDriveStatistics {

  // MARK: - Properties

  let name: String
  let distanceMetres: Double
  let durationSeconds: Int
  let averageSpeedKmh: Double
  let meanSpeedKmh: Double
  let speedStandardDeviationKmh: Double
  let speedVarianceKmh2: Double
  let percentTimeAbove80Kmh: Double
  let sustainedHighSpeedSegmentCount: Int
  let stopCount: Int
  let percentTimeStopped: Double
  let sinuosity: Double
  let bearingChangeRateDegreesPerKilometre: Double
  let elevationGainMetres: Double
  let elevationLossMetres: Double
}
