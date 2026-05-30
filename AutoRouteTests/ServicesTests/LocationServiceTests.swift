//
//  LocationServiceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
import Testing
import Foundation
import CoreLocation
import Combine

@Suite("LocationService")
struct LocationServiceTests {

  // MARK: - Tests

  @Test @MainActor
  func updatesStatusOnLifecycleCalls() throws {
    let service = LocationService()

    #expect(service.status == .stopped)

    service.start()
    #expect(service.status == .started)

    service.pause()
    #expect(service.status == .paused)

    service.resume()
    #expect(service.status == .started)

    service.stop()
    #expect(service.status == .stopped)
  }

  @Test @MainActor
  func publishesLocationThroughPublisher() throws {
    let service = LocationService()
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { location in
      receivedLocations.append(location)
    }

    let sampleLocation = CLLocation(latitude: 51.0, longitude: -0.1)
    service.locationManager(CLLocationManager(), didUpdateLocations: [sampleLocation])

    #expect(receivedLocations == [sampleLocation])

    cancellable.cancel()
  }
}
