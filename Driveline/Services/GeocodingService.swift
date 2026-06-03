//
//  GeocodingService.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import Foundation
import MapKit

// MARK: - Protocol

@MainActor
protocol GeocodingServiceProtocol {
  func reverseGeocode(location: CLLocation) async -> String?
}

// MARK: - GeocodingService

@MainActor
final class GeocodingService: GeocodingServiceProtocol {

  // MARK: - Types

  struct PlaceNameComponents {
    let subLocality: String?
    let locality: String?
    let cityWithContext: String?
    let cityName: String?
    let shortAddress: String?
    let name: String?
  }

  // MARK: - Actions

  func reverseGeocode(location: CLLocation) async -> String? {
    guard let request = MKReverseGeocodingRequest(location: location),
          let mapItem = try? await request.mapItems.first else { return nil }

    // Safe dynamic lookup to bypass the rigid compile-time warning
    let placemark = mapItem.value(forKey: "placemark") as? CLPlacemark

    let components = PlaceNameComponents(
      subLocality: placemark?.subLocality,
      locality: placemark?.locality,
      cityWithContext: mapItem.addressRepresentations?.cityWithContext,
      cityName: mapItem.addressRepresentations?.cityName,
      shortAddress: mapItem.address?.shortAddress,
      name: mapItem.name
    )
    return Self.composePlaceName(from: components)
  }

  // MARK: - Helpers

  nonisolated static func composePlaceName(from components: PlaceNameComponents) -> String? {
    if let subLocality = components.subLocality {
      if let locality = components.locality, locality != subLocality {
        return "\(subLocality), \(locality)"
      }
      return subLocality
    }
    if let cityWithContext = components.cityWithContext { return cityWithContext }
    if let cityName = components.cityName { return cityName }
    return components.shortAddress ?? components.name
  }
}
