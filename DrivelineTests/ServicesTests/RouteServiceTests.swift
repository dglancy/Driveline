//
//  RouteServiceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Combine
import CoreLocation
import Foundation
import SwiftData
import Testing

@MainActor
final class RouteServiceTests: SwiftDataBaseTestCase {

  // MARK: - startRoute

  @Test
  func startRouteCreatesRecordingRoute() async throws {
    let (service, locationService, recorder) = makeServices()

    try service.startRoute()

    #expect(service.route != nil)
    #expect(service.route!.isRecording == true)
    #expect(locationService.status == .started)
    #expect(recorder.route != nil)
  }

  @Test
  func startRouteSetsIsRecordingToTrue() async throws {
    let (service, _, _) = makeServices()

    try service.startRoute()

    #expect(service.isRecording == true)
  }

  @Test
  func startRouteResetsCurrentSpeedMs() async throws {
    let (service, _, _) = makeServices()

    try service.startRoute()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func startRouteGeneratesTimeBasedName() async throws {
    let (service, _, _) = makeServices()

    try service.startRoute()

    let validNames = ["Morning Drive", "Afternoon Drive", "Evening Drive", "Night Drive"]
    #expect(validNames.contains(service.route!.name))
  }

  // MARK: - finishRoute

  @Test
  func finishRouteStopsRecordingAndPersists() async throws {
    let (service, locationService, recorder) = makeServices()

    try service.startRoute()
    let startedRoute = service.route!
    service.finishRoute()

    #expect(locationService.status == .stopped)
    #expect(startedRoute.isRecording == false)
    #expect(startedRoute.endedAt != nil)
    #expect(recorder.route == nil)

    let persistedCount = try! count(where: #Predicate<Route> { _ in true })
    #expect(persistedCount == 1)
  }

  @Test
  func finishRouteSetsIsRecordingToFalse() async throws {
    let (service, _, _) = makeServices()

    try service.startRoute()
    service.finishRoute()

    #expect(service.isRecording == false)
  }

  @Test
  func finishRouteResetsCurrentSpeedMs() async throws {
    let (service, locationService, _) = makeServices()

    try service.startRoute()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    service.finishRoute()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func finishRouteWithNoActiveRouteDoesNothing() async throws {
    let (service, _, _) = makeServices()

    service.finishRoute()

    #expect(service.route == nil)
  }

  // MARK: - currentSpeedMs

  @Test
  func currentSpeedMsIsNilInitially() async throws {
    let (service, _, _) = makeServices()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func currentSpeedMsUpdatesWhenLocationPublished() async throws {
    let (service, locationService, _) = makeServices()

    try service.startRoute()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)

    #expect(service.currentSpeedMs == 14.0)
  }

  @Test
  func currentSpeedMsIsNilForInvalidLocationSpeed() async throws {
    let (service, locationService, _) = makeServices()

    try service.startRoute()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: -1, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func currentSpeedMsIsNilAfterFinishRoute() async throws {
    let (service, locationService, _) = makeServices()

    try service.startRoute()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    service.finishRoute()

    #expect(service.currentSpeedMs == nil)
  }

  // MARK: - initialRoute

  @Test
  func initialRouteIsSetOnInit() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let existingRoute = Route(name: "Existing route")
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialRoute: existingRoute)

    #expect(service.route?.id == existingRoute.id)
  }

  @Test
  func initialRouteWithIsRecordingTrueSetsIsRecordingToTrue() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.status = .recording
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialRoute: route)

    #expect(service.isRecording == true)
  }

  @Test
  func initialRouteWithIsRecordingFalseSetsIsRecordingToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.status = .finished
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialRoute: route)

    #expect(service.isRecording == false)
  }

  // MARK: - startRoute geocoding accuracy

  @Test
  func startRouteSetsStartPlaceNameFromAccurateLocation() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    try service.startRoute()

    let goodLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(goodLocation)

    await Task.yield()
    await Task.yield()

    #expect(service.route?.startPlaceName == "Test Place")
  }

  @Test
  func startRouteGeocodesOnlyOnceEvenWithMultipleGoodLocations() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    try service.startRoute()

    let firstGood = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    let secondGood = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.502, longitude: -0.102),
      altitude: 0, horizontalAccuracy: 8, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )

    locationService.locationPublisher.send(firstGood)
    locationService.locationPublisher.send(secondGood)

    await Task.yield()
    await Task.yield()

    #expect(mockGeocoding.geocodedLocations.count == 1)
  }

  // MARK: - Helpers

  private func makeServices(geocodingService: (any GeocodingServiceProtocol)? = nil) -> (RouteService, LocationService, LocationDataRecorderService) {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(
      modelContext: context!,
      locationService: locationService,
      locationDataRecorder: recorder,
      geocodingService: geocodingService ?? MockGeocodingService(),
      networkMonitorService: MockNetworkMonitorService()
    )
    return (service, locationService, recorder)
  }
}
