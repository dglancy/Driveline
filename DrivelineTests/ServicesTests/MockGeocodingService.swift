//
//  MockGeocodingService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import CoreLocation
import Foundation

@MainActor
final class MockGeocodingService: GeocodingServiceProtocol {

  // MARK: - Properties

  private(set) var geocodedLocations: [CLLocation] = []
  var result: String? = "Test Place"
  var onGeocode: (() -> Void)?
  var delay: Duration?

  // MARK: - GeocodingServiceProtocol

  func reverseGeocode(location: CLLocation) async -> String? {
    onGeocode?()
    geocodedLocations.append(location)
    if let delay {
      try? await Task.sleep(for: delay)
    }
    return result
  }
}
