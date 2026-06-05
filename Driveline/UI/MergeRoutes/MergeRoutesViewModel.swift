//
//  MergeRoutesViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class MergeRoutesViewModel {

  // MARK: - Properties

  private(set) var orderedRoutes: [Route]
  var mergedName: String

  // MARK: - Computed Properties

  var firstDisplay: RouteRowDisplay { makeDisplay(for: orderedRoutes[0]) }
  var secondDisplay: RouteRowDisplay { makeDisplay(for: orderedRoutes[1]) }

  var formattedTotalDistance: String {
    Measurement(value: orderedRoutes[0].distanceMetres + orderedRoutes[1].distanceMetres, unit: UnitLength.meters).localizedDistanceString()
  }

  var formattedTotalDuration: String {
    (orderedRoutes[0].activeDurationSeconds + orderedRoutes[1].activeDurationSeconds).localizedHoursMinutesString()
  }

  var formattedTotalPositionCount: String {
    (orderedRoutes[0].positions.count + orderedRoutes[1].positions.count).formatted()
  }

  // MARK: - Lifecycle

  init(routes: [Route]) {
    precondition(routes.count == 2, "MergeRoutesViewModel requires exactly 2 routes")
    self.orderedRoutes = routes
    self.mergedName = String(localized: "\(routes[0].name) + \(routes[1].name)", comment: "Default name for a merged route, combining two route names with a plus sign")
  }

  // MARK: - Methods

  func swapOrder() {
    orderedRoutes = [orderedRoutes[1], orderedRoutes[0]]
    mergedName = String(localized: "\(orderedRoutes[0].name) + \(orderedRoutes[1].name)", comment: "Default name for a merged route, combining two route names with a plus sign")
  }

  // MARK: - Private

  private func makeDisplay(for route: Route) -> RouteRowDisplay {
    let parts: [String?] = [RouteStatsPresenter(route: route).startTimeLabel, route.startPlaceName]
    return RouteRowDisplay(
      name: route.name,
      dateTimeLabel: parts.compactMap { $0 }.joined(separator: " · "),
      formattedDistance: Measurement(value: route.distanceMetres, unit: UnitLength.meters).localizedDistanceString(),
      formattedDuration: route.activeDurationSeconds.localizedHoursMinutesString()
    )
  }
}
