//
//  RecordingViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class RecordingViewModel {

  // MARK: - Properties

  @ObservationIgnored private let driveService: DriveRecordingService

  // MARK: - Computed Properties

  var elapsedSeconds: Int { Int(driveService.drive?.activeDurationSeconds ?? 0) }
  var distanceMetres: Double { driveService.drive?.accumulatedDistanceMetres ?? 0.0 }

  var elapsedDisplay: String { TimeInterval(elapsedSeconds).elapsedTimeString() }

  var elapsedSpeechValue: String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .spellOut
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropLeading
    return formatter.string(from: TimeInterval(elapsedSeconds)) ?? elapsedDisplay
  }
  var distanceValue: String {
    Measurement(value: distanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
  }
  var distanceUnit: String {
    Measurement(value: distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
  }

  var speedValue: String {
    guard let ms = driveService.currentSpeedMs else { return kDashString }
    return Measurement(value: ms, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString()
  }

  var speedUnit: String {
    Measurement(value: driveService.currentSpeedMs ?? 0, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol()
  }
  var positionCount: Int { driveService.drive?.positions.count ?? 0 }

  var formattedPositionCount: String {
    Self.formattedCount(positionCount)
  }

  var startedAt: String {
    guard let date = driveService.drive?.startedAt else { return kDashString }
    return date.clockString()
  }

  // MARK: - Formatting

  private static let positionCountFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  static func formattedCount(_ count: Int) -> String {
    if count < 100_000 {
      return positionCountFormatter.string(from: NSNumber(value: count)) ?? count.formatted()
    }
    return count.formatted(.number.notation(.compactName))
  }

  // MARK: - Lifecycle

  init(driveService: DriveRecordingService) {
    self.driveService = driveService
  }

  // MARK: - Actions

  func finishDrive() {
    driveService.finishDrive()
  }
}
