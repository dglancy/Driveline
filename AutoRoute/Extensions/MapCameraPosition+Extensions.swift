//
//  MapCameraPosition+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit
import SwiftUI

extension MapCameraPosition {

  static func fit(
    to coordinates: [CLLocationCoordinate2D],
    paddingMultiplier: CLLocationDegrees = 1.5
  ) -> MapCameraPosition {
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
    let latDelta = max((maxLat - minLat) * paddingMultiplier, 0.005)
    let lonDelta = max((maxLon - minLon) * paddingMultiplier, 0.005)
    return .region(MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)))
  }
}
