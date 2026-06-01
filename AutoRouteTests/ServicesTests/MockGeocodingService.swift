//
//  MockGeocodingService.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import AutoRoute
import CoreLocation
import Foundation

@MainActor
final class MockGeocodingService: GeocodingServiceProtocol {

  // MARK: - Properties

  private(set) var geocodedLocations: [CLLocation] = []
  var result: String? = "Test Place"

  // MARK: - GeocodingServiceProtocol

  func reverseGeocode(location: CLLocation) async -> String? {
    geocodedLocations.append(location)
    return result
  }
}
