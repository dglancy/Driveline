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
    guard !coordinates.isEmpty else { return .automatic }
    return .region(.fitting(coordinates, paddingMultiplier: paddingMultiplier))
  }
}
