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

// MARK: - Protocol

@MainActor
protocol DriveClassifierServiceProtocol {
  func classify(_ drive: Drive) async
}

// MARK: - DriveClassifierService

@MainActor
@Observable
final class DriveClassifierService: DriveClassifierServiceProtocol {

  // MARK: - Properties

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let model: DriveCategoryClassifier?

  // MARK: - Lifecycle

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    self.model = Self.loadModel()
  }

  // MARK: - Actions

  func classify(_ drive: Drive) async {
    guard let model else { return }

    let input = DriveCategoryClassifierInput(
      Distance: drive.displayDistanceMetres,
      Duration: Int64(drive.activeDurationSeconds),
      Average_Speed: drive.avgSpeedMetresPerSecond * Constants.Statistics.metresPerSecondToKilometresPerHour,
      Mean_Speed: drive.meanSpeedMetresPerSecond * Constants.Statistics.metresPerSecondToKilometresPerHour,
      Std_Deviation_Speed: drive.speedStandardDeviationMetresPerSecond * Constants.Statistics.metresPerSecondToKilometresPerHour,
      Speed_Variance: drive.speedVarianceMetresPerSecondSquared * pow(Constants.Statistics.metresPerSecondToKilometresPerHour, 2),
      Percentage_Time_At_High_Speed: drive.fractionOfTimeAboveHighSpeed * 100,
      Sustained_High_Speed_Segment_Count: Int64(drive.sustainedHighSpeedSegmentCount),
      Stop_Count: Int64(drive.stopCount),
      Percentage_Time_Stopped: drive.fractionOfTimeStopped * 100,
      Sinuosity: drive.sinuosity,
      Bearing_Change_Rate: drive.bearingChangeRateDegreesPerKilometre,
      Elevation_Gain: drive.elevationGainMetres,
      Elevation_Loss: drive.elevationLossMetres
    )

    do {
      let output = try predict(model, input: input)
      drive.category = Drive.Category.from(string: output.Category)
      saveModelContext()
    } catch {
      Log.data.error("Drive classification failed: \(error.localizedDescription)")
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

  private func saveModelContext() {
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context after drive classification: \(error.localizedDescription)")
    }
  }
}
