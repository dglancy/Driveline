//
//  DriveSection.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

struct DriveRow: Identifiable {

  // MARK: - Properties

  let drive: Drive
  var id: UUID { drive.id }

  // MARK: - Computed Properties

  @MainActor
  var display: DriveRowDisplay {
    let duration = drive.endedAt != nil ? drive.activeDurationSeconds.localizedHoursMinutesString() : nil
    let distance = Measurement(value: drive.displayDistanceMetres, unit: UnitLength.meters)
    return DriveRowDisplay(
      dateTimeLabel: DriveStatsPresenter(drive: drive).startTimeLabel,
      formattedDistance: distance.localizedDistanceString(),
      formattedDuration: duration,
      iconName: DriveRowDisplay.iconName(for: drive.startedAt)
    )
  }
}

struct DriveSection: Identifiable {
  var id: String { title }
  let title: String
  let rows: [DriveRow]
}
