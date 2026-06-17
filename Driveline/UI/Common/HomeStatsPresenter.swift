//
//  HomeStatsPresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import Foundation

@MainActor
struct HomeStatsPresenter {

  // MARK: - Properties

  private let stats: DriveStats

  // MARK: - Lifecycle

  init(stats: DriveStats) {
    self.stats = stats
  }

  // MARK: - Computed Properties

  var driveCount: Int { stats.driveCount }

  var distanceValue: String {
    Measurement(value: stats.totalDistanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
  }

  var distanceUnit: String {
    Measurement(value: stats.totalDistanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
  }
}
