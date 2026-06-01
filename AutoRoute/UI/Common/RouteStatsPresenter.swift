//
//  RouteStatsPresenter.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation

struct RouteStatsPresenter {

  // MARK: - Properties

  private let route: Route

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
  }

  // MARK: - Computed Properties

  var distanceValue: String {
    Measurement(value: route.distanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
  }
  var distanceUnit: String {
    Measurement(value: route.distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
  }
  var durationValue: String { route.activeDurationSeconds.localizedHoursMinutesString() }
  var durationUnit: String { String(localized: "active", comment: "Active duration (not including pauses)") }
  var avgSpeedValue: String {
    Measurement(value: route.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString()
  }
  var avgSpeedUnit: String {
    Measurement(value: route.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol()
  }

  var startTimeLabel: String {
    let datePart = route.startedAt.abbreviatedMonthAndDay()
    let timePart = route.startedAt.clockTime()
    return "\(datePart) · \(timePart)"
  }
}
