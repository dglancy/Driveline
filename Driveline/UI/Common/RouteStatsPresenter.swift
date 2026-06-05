//
//  DriveStatsPresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation

struct DriveStatsPresenter {

  // MARK: - Properties

  private let drive: Drive

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
  }

  // MARK: - Computed Properties

  var distanceValue: String {
    Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
  }
  var distanceUnit: String {
    Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
  }
  var durationValue: String { drive.activeDurationSeconds.localizedHoursMinutesString() }
  var durationUnit: String { String(localized: "active", comment: "Label for the active driving duration stat") }
  var avgSpeedValue: String {
    Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString()
  }
  var avgSpeedUnit: String {
    Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol()
  }

  var startTimeLabel: String {
    let datePart = drive.startedAt.abbreviatedMonthAndDay()
    let timePart = drive.startedAt.clockString()
    return String(localized: "\(datePart) · \(timePart)", comment: "Drive start date and time, e.g. '5 Jun · 09:41'. Translators may change the separator.")
  }
}
