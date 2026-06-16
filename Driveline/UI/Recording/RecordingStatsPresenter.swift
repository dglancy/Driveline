//
//  RecordingStatsPresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

@MainActor
struct RecordingStatsPresenter {

  // MARK: - Properties

  private let elapsedSeconds: Int
  private let distanceMetres: Double
  private let positionCount: Int
  private let driveStartedAt: Date?

  // MARK: - Lifecycle

  init(driveService: DriveRecordingService) {
    elapsedSeconds = Int(driveService.drive?.activeDurationSeconds ?? 0)
    distanceMetres = driveService.drive?.accumulatedDistanceMetres ?? 0.0
    positionCount = driveService.drive?.positions?.count ?? 0
    driveStartedAt = driveService.drive?.startedAt
  }

  // MARK: - Computed Properties

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

  var formattedPositionCount: String {
    Self.formattedCount(positionCount)
  }

  var startedAt: String {
    guard let date = driveStartedAt else { return Constants.App.dashString }
    return date.clockString()
  }

  // MARK: - Static Formatting

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
}
