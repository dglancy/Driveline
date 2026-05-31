//
//  MergeRoutesViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class MergeRoutesViewModel {

  // MARK: - Properties

  private(set) var orderedRoutes: [Route]
  var mergedName: String

  // MARK: - Computed Properties

  var first: Route { orderedRoutes[0] }
  var second: Route { orderedRoutes[1] }

  var formattedTotalDistance: String {
    (first.distanceMetres + second.distanceMetres).localizedDistanceString()
  }

  var formattedTotalDuration: String {
    (first.activeDurationSeconds + second.activeDurationSeconds).localizedDurationString()
  }

  var totalPositionCount: Int {
    first.positions.count + second.positions.count
  }

  // MARK: - Lifecycle

  init(routes: [Route]) {
    precondition(routes.count == 2, "MergeRoutesViewModel requires exactly 2 routes")
    self.orderedRoutes = routes
    self.mergedName = "\(routes[0].name) + \(routes[1].name)"
  }

  // MARK: - Methods

  func swapOrder() {
    orderedRoutes = [orderedRoutes[1], orderedRoutes[0]]
    mergedName = "\(orderedRoutes[0].name) + \(orderedRoutes[1].name)"
  }
}
