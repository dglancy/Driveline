//
//  MergeDrivesPresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

@MainActor
struct MergeDrivesPresenter {

  // MARK: - Properties

  private let drives: [Drive]

  // MARK: - Lifecycle

  init(drives: [Drive]) {
    precondition(drives.count == 2)
    self.drives = drives
  }

  // MARK: - Computed Properties

  var firstDisplay: DriveRowDisplay { makeDisplay(for: drives[0]) }
  var secondDisplay: DriveRowDisplay { makeDisplay(for: drives[1]) }

  var formattedTotalDistance: String {
    Measurement(
      value: drives[0].distanceMetres + drives[1].distanceMetres,
      unit: UnitLength.meters
    ).localizedDistanceString()
  }

  var formattedTotalDuration: String {
    (drives[0].activeDurationSeconds + drives[1].activeDurationSeconds).localizedHoursMinutesString()
  }

  var formattedTotalPositionCount: String {
    ((drives[0].positions?.count ?? 0) + (drives[1].positions?.count ?? 0)).formatted()
  }

  // MARK: - Static

  static func defaultMergedName(for drives: [Drive]) -> String {
    String(
      localized: "\(drives[0].displayName) + \(drives[1].displayName)",
      comment: "Default name for a merged drive, combining two drive names with a plus sign"
    )
  }

  // MARK: - Private

  private func makeDisplay(for drive: Drive) -> DriveRowDisplay {
    let parts: [String?] = [DriveStatsPresenter(drive: drive).startTimeLabel, drive.startPlaceName]
    return DriveRowDisplay(
      dateTimeLabel: parts.compactMap { $0 }.joined(separator: " · "),
      formattedDistance: Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceString(),
      formattedDuration: drive.activeDurationSeconds.localizedHoursMinutesString(),
      iconName: DriveRowDisplay.iconName(for: drive.startedAt)
    )
  }
}
