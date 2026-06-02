//
//  LocationServiceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoutes
import Testing
import Foundation
import CoreLocation
import Combine

@Suite("LocationService")
struct LocationServiceTests {

  // MARK: - Tests

  @Test
  @MainActor
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

  @Test
  @MainActor
  func publishesValidLocationThroughPublisher() async throws {
    let service = LocationService()
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { location in
      receivedLocations.append(location)
    }

    let validLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date()
    )
    service.locationManager(CLLocationManager(), didUpdateLocations: [validLocation])

    await Task.yield()

    #expect(receivedLocations.count == 1)

    cancellable.cancel()
  }

  @Test
  @MainActor
  func doesNotPublishLocationWithNegativeAccuracy() async throws {
    let service = LocationService()
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let staleLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: -1, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    service.locationManager(CLLocationManager(), didUpdateLocations: [staleLocation])

    await Task.yield()

    #expect(receivedLocations.isEmpty)

    cancellable.cancel()
  }

  @Test
  @MainActor
  func doesNotPublishLocationBeyondAccuracyThreshold() async throws {
    let service = LocationService()
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let poorLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 200, verticalAccuracy: 10,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    service.locationManager(CLLocationManager(), didUpdateLocations: [poorLocation])

    await Task.yield()

    #expect(receivedLocations.isEmpty)

    cancellable.cancel()
  }

  @Test
  @MainActor
  func doesNotPublishStaleLocation() async throws {
    let service = LocationService()
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let staleTimestamp = Date().addingTimeInterval(-(kMaxLocationAge + 1))
    let staleLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: staleTimestamp
    )
    service.locationManager(CLLocationManager(), didUpdateLocations: [staleLocation])

    await Task.yield()

    #expect(receivedLocations.isEmpty)

    cancellable.cancel()
  }

  // MARK: - isUsable

  @Test
  @MainActor
  func isUsableReturnsTrueForValidLocation() {
    let service = LocationService()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date()
    )
    #expect(service.isUsable(location) == true)
  }

  @Test
  @MainActor
  func isUsableReturnsFalseForNegativeAccuracy() {
    let service = LocationService()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: -1, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    #expect(service.isUsable(location) == false)
  }

  @Test
  @MainActor
  func isUsableReturnsFalseForAccuracyAtThreshold() {
    let service = LocationService()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: kMinimumLocationAccuracy, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    #expect(service.isUsable(location) == false)
  }

  @Test
  @MainActor
  func isUsableReturnsFalseForStaleTimestamp() {
    let service = LocationService()
    let staleTimestamp = Date().addingTimeInterval(-(kMaxLocationAge + 1))
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: staleTimestamp
    )
    #expect(service.isUsable(location) == false)
  }
}
