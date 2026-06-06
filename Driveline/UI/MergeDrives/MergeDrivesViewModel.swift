//
//  MergeDrivesViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class MergeDrivesViewModel {

  // MARK: - Properties

  private(set) var orderedDrives: [Drive]
  var mergedName: String

  // MARK: - Computed Properties

  var firstDisplay: DriveRowDisplay { makeDisplay(for: orderedDrives[0]) }
  var secondDisplay: DriveRowDisplay { makeDisplay(for: orderedDrives[1]) }

  var formattedTotalDistance: String {
    Measurement(value: orderedDrives[0].distanceMetres + orderedDrives[1].distanceMetres, unit: UnitLength.meters).localizedDistanceString()
  }

  var formattedTotalDuration: String {
    (orderedDrives[0].activeDurationSeconds + orderedDrives[1].activeDurationSeconds).localizedHoursMinutesString()
  }

  var formattedTotalPositionCount: String {
    ((orderedDrives[0].positions?.count ?? 0) + (orderedDrives[1].positions?.count ?? 0)).formatted()
  }

  // MARK: - Lifecycle

  init(drives: [Drive]) {
    precondition(drives.count == 2, "MergeDrivesViewModel requires exactly 2 drives")
    self.orderedDrives = drives
    self.mergedName = Self.defaultMergedName(for: drives)
  }

  // MARK: - Methods

  func swapOrder() {
    orderedDrives = [orderedDrives[1], orderedDrives[0]]
    mergedName = Self.defaultMergedName(for: orderedDrives)
  }

  // MARK: - Private

  private static func defaultMergedName(for drives: [Drive]) -> String {
    String(localized: "\(drives[0].displayName) + \(drives[1].displayName)", comment: "Default name for a merged drive, combining two drive names with a plus sign")
  }

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
