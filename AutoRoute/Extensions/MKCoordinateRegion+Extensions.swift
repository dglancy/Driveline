//
//  MKCoordinateRegion+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit

extension MKCoordinateRegion {

  static func fitting(
    _ coordinates: [CLLocationCoordinate2D],
    paddingMultiplier: CLLocationDegrees = 1.5,
    minimumSpan: CLLocationDegrees = 0.005,
    aspectRatio: CGFloat? = nil
  ) -> MKCoordinateRegion {
    guard let first = coordinates.first else { return .init() }

    var minLat = first.latitude
    var maxLat = first.latitude
    var minLon = first.longitude
    var maxLon = first.longitude

    for coord in coordinates {
      minLat = min(minLat, coord.latitude)
      maxLat = max(maxLat, coord.latitude)
      minLon = min(minLon, coord.longitude)
      maxLon = max(maxLon, coord.longitude)
    }

    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                        longitude: (minLon + maxLon) / 2)
    let centerLatitudeRadians = center.latitude * .pi / 180
    let longitudeScale = max(cos(centerLatitudeRadians), 0.0001)

    let latitudeDelta = max(maxLat - minLat, minimumSpan) * paddingMultiplier
    let longitudeDelta = max(maxLon - minLon, minimumSpan) * paddingMultiplier
    let normalizedLongitudeDelta = longitudeDelta * cos(centerLatitudeRadians)

    var adjustedLonNormalized = normalizedLongitudeDelta
    var adjustedLat = latitudeDelta

    if let aspectRatio {
      if adjustedLonNormalized / adjustedLat < aspectRatio {
        adjustedLonNormalized = adjustedLat * aspectRatio
      } else {
        adjustedLat = adjustedLonNormalized / aspectRatio
      }
    }

    let adjustedLon = max(adjustedLonNormalized / longitudeScale, minimumSpan)
    let span = MKCoordinateSpan(latitudeDelta: max(adjustedLat, minimumSpan),
                                longitudeDelta: adjustedLon)
    return MKCoordinateRegion(center: center, span: span)
  }
}
