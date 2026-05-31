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

  var distanceValue: String { route.distanceMetres.localizedDistanceValueString() }
  var distanceUnit: String { route.distanceMetres.localizedDistanceUnitSymbol() }
  var durationValue: String { route.activeDurationSeconds.localizedHoursMinutesString() }
  var avgSpeedValue: String { route.avgSpeedMetresPerSecond.localizedSpeedValueString() }
  var avgSpeedUnit: String { route.avgSpeedMetresPerSecond.localizedSpeedUnitSymbol() }

  var startTimeLabel: String {
    let datePart = route.startedAt.formatted(.dateTime.month(.abbreviated).day())
    let timePart = route.startedAt.formatted(.dateTime.hour().minute())
    return "\(datePart) · \(timePart)"
  }
}
