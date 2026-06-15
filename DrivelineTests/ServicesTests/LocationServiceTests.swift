//
//  LocationServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
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
    let streamProvider = MockLocationStreamProvider()
    let sessionProvider = MockBackgroundActivitySessionProvider()
    let service = LocationService(streamProvider: streamProvider, sessionProvider: sessionProvider)

    #expect(service.status == .stopped)

    service.start()
    #expect(service.status == .started)
    #expect(sessionProvider.beginCallCount == 1)

    service.stop()
    #expect(service.status == .stopped)
    #expect(sessionProvider.session.invalidateCallCount == 1)
  }

  @Test
  @MainActor
  func publishesValidLocationThroughPublisher() async throws {
    let streamProvider = MockLocationStreamProvider()
    let service = LocationService(streamProvider: streamProvider, sessionProvider: MockBackgroundActivitySessionProvider())
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let validLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date()
    )

    service.start()
    streamProvider.send(validLocation)
    try await Task.sleep(for: .milliseconds(200))

    #expect(receivedLocations.count == 1)
    #expect(receivedLocations.first?.coordinate.latitude == validLocation.coordinate.latitude)

    cancellable.cancel()
  }

  @Test
  @MainActor
  func doesNotPublishLocationWithNegativeAccuracy() async throws {
    let streamProvider = MockLocationStreamProvider()
    let service = LocationService(streamProvider: streamProvider, sessionProvider: MockBackgroundActivitySessionProvider())
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let staleLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: -1, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )

    service.start()
    streamProvider.send(staleLocation)
    try await Task.sleep(for: .milliseconds(200))

    #expect(receivedLocations.isEmpty)

    cancellable.cancel()
  }

  @Test
  @MainActor
  func doesNotPublishLocationBeyondAccuracyThreshold() async throws {
    let streamProvider = MockLocationStreamProvider()
    let service = LocationService(streamProvider: streamProvider, sessionProvider: MockBackgroundActivitySessionProvider())
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let poorLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 200, verticalAccuracy: 10,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )

    service.start()
    streamProvider.send(poorLocation)
    try await Task.sleep(for: .milliseconds(200))

    #expect(receivedLocations.isEmpty)

    cancellable.cancel()
  }

  @Test
  @MainActor
  func doesNotPublishStaleLocation() async throws {
    let streamProvider = MockLocationStreamProvider()
    let service = LocationService(streamProvider: streamProvider, sessionProvider: MockBackgroundActivitySessionProvider())
    var receivedLocations = [CLLocation]()
    let cancellable = service.locationPublisher.sink { receivedLocations.append($0) }

    let staleTimestamp = Date().addingTimeInterval(-(Constants.Configuration.maxLocationAge + 1))
    let staleLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: staleTimestamp
    )

    service.start()
    streamProvider.send(staleLocation)
    try await Task.sleep(for: .milliseconds(200))

    #expect(receivedLocations.isEmpty)

    cancellable.cancel()
  }

  // MARK: - isUsable

  @Test
  @MainActor
  func isUsableReturnsTrueForValidLocation() {
    let service = LocationService(streamProvider: MockLocationStreamProvider(), sessionProvider: MockBackgroundActivitySessionProvider())
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
    let service = LocationService(streamProvider: MockLocationStreamProvider(), sessionProvider: MockBackgroundActivitySessionProvider())
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
    let service = LocationService(streamProvider: MockLocationStreamProvider(), sessionProvider: MockBackgroundActivitySessionProvider())
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: Constants.Configuration.minimumLocationAccuracy, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    #expect(service.isUsable(location) == false)
  }

  @Test
  @MainActor
  func isUsableReturnsFalseForStaleTimestamp() {
    let service = LocationService(streamProvider: MockLocationStreamProvider(), sessionProvider: MockBackgroundActivitySessionProvider())
    let staleTimestamp = Date().addingTimeInterval(-(Constants.Configuration.maxLocationAge + 1))
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.0, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: staleTimestamp
    )
    #expect(service.isUsable(location) == false)
  }
}
