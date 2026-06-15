//
//  DriveClassifierService.swift
//  Driveline
//
//  Created by Damien Glancy on 12/06/2026.
//

import CoreML
import Foundation
import Observation
import SwiftData

// MARK: - DriveClassificationInput

struct DriveClassificationInput: Sendable {

  // MARK: - Properties

  let distanceMetres: Double
  let durationSeconds: Int64
  let averageSpeedKilometresPerHour: Double
  let meanSpeedKilometresPerHour: Double
  let speedStandardDeviationKilometresPerHour: Double
  let speedVarianceKilometresPerHourSquared: Double
  let percentageTimeAtHighSpeed: Double
  let sustainedHighSpeedSegmentCount: Int64
  let stopCount: Int64
  let percentageTimeStopped: Double
  let sinuosity: Double
  let bearingChangeRateDegreesPerKilometre: Double
  let elevationGainMetres: Double
  let elevationLossMetres: Double

  // MARK: - Lifecycle

  nonisolated init(drive: Drive) {
    let stats = drive.routeStatistics()
    let activeDuration = drive.activeDurationSeconds

    distanceMetres = drive.displayDistanceMetres
    durationSeconds = Int64(activeDuration)
    averageSpeedKilometresPerHour = (activeDuration > 0 ? stats.distanceMetres / activeDuration : 0) * Constants.Statistics.metresPerSecondToKilometresPerHour
    meanSpeedKilometresPerHour = stats.meanSpeedMetresPerSecond * Constants.Statistics.metresPerSecondToKilometresPerHour
    speedStandardDeviationKilometresPerHour = stats.speedStandardDeviationMetresPerSecond * Constants.Statistics.metresPerSecondToKilometresPerHour
    speedVarianceKilometresPerHourSquared = stats.speedVarianceMetresPerSecondSquared * pow(Constants.Statistics.metresPerSecondToKilometresPerHour, 2)
    percentageTimeAtHighSpeed = stats.fractionOfTimeAboveHighSpeed * 100
    sustainedHighSpeedSegmentCount = Int64(stats.sustainedHighSpeedSegmentCount)
    stopCount = Int64(stats.stopCount)
    percentageTimeStopped = stats.fractionOfTimeStopped * 100
    sinuosity = stats.sinuosity
    bearingChangeRateDegreesPerKilometre = stats.bearingChangeRateDegreesPerKilometre
    elevationGainMetres = stats.elevationGainMetres
    elevationLossMetres = stats.elevationLossMetres
  }
}

// MARK: - Protocol

protocol DriveClassifierServiceProtocol: Sendable {
  func classify(_ input: DriveClassificationInput) -> Drive.Category
}

// MARK: - DriveClassifierService

final class DriveClassifierService: DriveClassifierServiceProtocol, @unchecked Sendable {

  // MARK: - Properties

  private let model: DriveCategoryClassifier?

  // MARK: - Lifecycle

  init() {
    self.model = Self.loadModel()
  }

  // MARK: - Actions

  func classify(_ input: DriveClassificationInput) -> Drive.Category {
    guard let model else { return .none }

    let mlInput = DriveCategoryClassifierInput(
      Distance: input.distanceMetres,
      Duration: input.durationSeconds,
      Average_Speed: input.averageSpeedKilometresPerHour,
      Mean_Speed: input.meanSpeedKilometresPerHour,
      Std_Deviation_Speed: input.speedStandardDeviationKilometresPerHour,
      Speed_Variance: input.speedVarianceKilometresPerHourSquared,
      Percentage_Time_At_High_Speed: input.percentageTimeAtHighSpeed,
      Sustained_High_Speed_Segment_Count: input.sustainedHighSpeedSegmentCount,
      Stop_Count: input.stopCount,
      Percentage_Time_Stopped: input.percentageTimeStopped,
      Sinuosity: input.sinuosity,
      Bearing_Change_Rate: input.bearingChangeRateDegreesPerKilometre,
      Elevation_Gain: input.elevationGainMetres,
      Elevation_Loss: input.elevationLossMetres
    )

    do {
      let output = try predict(model, input: mlInput)
      return Drive.Category.from(string: output.Category)
    } catch {
      Log.data.error("Drive classification failed: \(error.localizedDescription)")
      return .none
    }
  }

  // MARK: - Private

  private func predict(_ model: DriveCategoryClassifier, input: DriveCategoryClassifierInput) throws -> DriveCategoryClassifierOutput {
    try model.prediction(input: input)
  }

  private static func loadModel() -> DriveCategoryClassifier? {
    do {
      return try DriveCategoryClassifier(configuration: MLModelConfiguration())
    } catch {
      Log.data.error("Failed to load DriveCategoryClassifier model: \(error.localizedDescription)")
      return nil
    }
  }
}
