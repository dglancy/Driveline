//
//  FullScreenMapViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftUI

@MainActor
@Observable
final class FullScreenMapViewModel {

  // MARK: - Properties

  @ObservationIgnored let route: Route
  @ObservationIgnored private let stats: RouteStatsPresenter

  // MARK: - Computed Properties

  var name: String { route.name }

  var distanceValue: String { stats.distanceValue }
  var distanceUnit: String { stats.distanceUnit }
  var durationValue: String { stats.durationValue }
  var durationUnit: String { stats.durationUnit }
  var avgSpeedValue: String { stats.avgSpeedValue }
  var avgSpeedUnit: String { stats.avgSpeedUnit }

  var coordinates: [CLLocationCoordinate2D] {
    route.orderedPositions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  var cameraPosition: MapCameraPosition {
    .fit(to: coordinates, paddingMultiplier: 2.0)
  }

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
    self.stats = RouteStatsPresenter(route: route)
  }
}
