//
//  FullScreenMapViewModel.swift
//  AutoRoute
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

  // MARK: - Computed Properties

  var name: String { route.name }

  var distanceValue: String { route.distanceMetres.localizedDistanceValueString() }
  var distanceUnit: String { route.distanceMetres.localizedDistanceUnitSymbol() }

  var durationValue: String { route.activeDurationSeconds.localizedHoursMinutesString() }

  var avgSpeedValue: String { route.avgSpeedMetresPerSecond.localizedSpeedValueString() }
  var avgSpeedUnit: String { route.avgSpeedMetresPerSecond.localizedSpeedUnitSymbol() }

  var coordinates: [CLLocationCoordinate2D] {
    route.orderedPositions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  var cameraPosition: MapCameraPosition {
    guard coordinates.count > 1 else {
      return coordinates.first.map {
        .region(MKCoordinateRegion(center: $0, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
      } ?? .automatic
    }
    let lats = coordinates.map(\.latitude)
    let lons = coordinates.map(\.longitude)
    guard let minLat = lats.min(), let maxLat = lats.max(),
          let minLon = lons.min(), let maxLon = lons.max() else { return .automatic }
    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
    let latDelta = max((maxLat - minLat) * 2.0, 0.005)
    let lonDelta = max((maxLon - minLon) * 2.0, 0.005)
    return .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)))
  }

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
  }
}
