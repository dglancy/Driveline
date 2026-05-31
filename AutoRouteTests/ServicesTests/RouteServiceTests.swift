//
//  RouteServiceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
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

    service.startRoute()

    #expect(service.route != nil)
    #expect(service.route!.isRecording == true)
    #expect(locationService.status == .started)
    #expect(recorder.route != nil)
  }

  @Test
  func startRouteSetsIsRecordingToTrue() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()

    #expect(service.isRecording == true)
  }

  @Test
  func startRouteSetsIsPausedToFalse() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()

    #expect(service.isPaused == false)
  }

  @Test
  func startRouteResetsCurrentSpeedMs() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func startRouteGeneratesTimeBasedName() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()

    let validNames = ["Morning Drive", "Afternoon Drive", "Evening Drive", "Night Drive"]
    #expect(validNames.contains(service.route!.name))
  }

  // MARK: - endRoute

  @Test
  func endRouteStopsRecordingAndPersists() async throws {
    let (service, locationService, recorder) = makeServices()

    service.startRoute()
    let startedRoute = service.route!
    await service.endRoute()

    #expect(locationService.status == .stopped)
    #expect(startedRoute.isRecording == false)
    #expect(startedRoute.endedAt != nil)
    #expect(recorder.route == nil)

    let persistedCount = try! count(where: #Predicate<Route> { _ in true })
    #expect(persistedCount == 1)
  }

  @Test
  func endRouteSetsIsRecordingToFalse() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    await service.endRoute()

    #expect(service.isRecording == false)
  }

  @Test
  func endRouteSetsIsPausedToFalse() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    await service.endRoute()

    #expect(service.isPaused == false)
  }

  @Test
  func endRouteSetsIsPausedToFalseOnRouteModel() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    let route = service.route!
    await service.endRoute()

    #expect(route.isPaused == false)
  }

  @Test
  func endRouteResetsCurrentSpeedMs() async throws {
    let (service, locationService, _) = makeServices()

    service.startRoute()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    await service.endRoute()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func endRouteWithNoActiveRouteDoesNothing() async throws {
    let (service, _, _) = makeServices()

    await service.endRoute()

    #expect(service.route == nil)
  }

  // MARK: - pauseRoute

  @Test
  func pauseRoutePausesLocationService() async throws {
    let (service, locationService, _) = makeServices()

    service.startRoute()
    service.pauseRoute()

    #expect(locationService.status == .paused)
  }

  @Test
  func pauseRouteSetsIsPausedToTrue() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()

    #expect(service.isPaused == true)
  }

  @Test
  func pauseRouteSetsIsPausedOnRouteModel() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()

    #expect(service.route?.isPaused == true)
  }

  @Test
  func pauseRouteSetsPauseStartedAtOnRouteModel() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()

    #expect(service.route?.pauseStartedAt != nil)
  }

  // MARK: - resumeRoute

  @Test
  func resumeRouteResumesLocationService() async throws {
    let (service, locationService, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    service.resumeRoute()

    #expect(locationService.status == .started)
  }

  @Test
  func resumeRouteSetsIsPausedToFalse() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    service.resumeRoute()

    #expect(service.isPaused == false)
  }

  @Test
  func resumeRouteSetsIsPausedToFalseOnRouteModel() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    service.resumeRoute()

    #expect(service.route?.isPaused == false)
  }

  @Test
  func resumeRouteClearsPauseStartedAtOnRouteModel() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    service.resumeRoute()

    #expect(service.route?.pauseStartedAt == nil)
  }

  @Test
  func resumeRouteAccumulatesPausedDurationSeconds() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    service.resumeRoute()

    #expect(service.route?.pausedDurationSeconds ?? -1 >= 0)
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

    service.startRoute()

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

    service.startRoute()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: -1, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func currentSpeedMsIsNilAfterEndRoute() async throws {
    let (service, locationService, _) = makeServices()

    service.startRoute()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    await service.endRoute()

    #expect(service.currentSpeedMs == nil)
  }

  // MARK: - initialRoute

  @Test
  func initialRouteIsSetOnInit() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let existingRoute = Route(name: "Existing route")
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: existingRoute)

    #expect(service.route?.id == existingRoute.id)
  }

  @Test
  func initialRouteWithIsRecordingTrueSetsIsRecordingToTrue() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.status = .recording
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isRecording == true)
  }

  @Test
  func initialRouteWithIsRecordingFalseSetsIsRecordingToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.status = .finished
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isRecording == false)
  }

  @Test
  func initialRouteWithIsPausedTrueSetsIsPausedToTrue() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.status = .paused
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isPaused == true)
  }

  @Test
  func initialRouteWithIsPausedFalseSetsIsPausedToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.status = .recording
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isPaused == false)
  }

  // MARK: - checkAndAutoFinishIfTimedOut

  @Test
  func checkAndAutoFinishIfTimedOutDoesNothingWithNoRoute() async throws {
    let (service, _, _) = makeServices()

    await service.checkAndAutoFinishIfTimedOut()

    #expect(service.route == nil)
    #expect(service.isRecording == false)
  }

  @Test
  func checkAndAutoFinishIfTimedOutDoesNothingWhenRouteIsRecording() async throws {
    let (service, _, _) = makeServices()
    service.startRoute()

    await service.checkAndAutoFinishIfTimedOut()

    #expect(service.isRecording == true)
    #expect(service.isPaused == false)
  }

  @Test
  func checkAndAutoFinishIfTimedOutDoesNothingWhenPausedBelowThreshold() async throws {
    let (service, _, _) = makeServices()
    service.startRoute()
    service.pauseRoute()

    await service.checkAndAutoFinishIfTimedOut()

    #expect(service.isPaused == true)
    #expect(service.isRecording == true)
  }

  @Test
  func checkAndAutoFinishIfTimedOutFinishesRouteWhenPausedBeyondThreshold() async throws {
    let (service, _, _) = makeServices()
    service.startRoute()
    service.pauseRoute()
    service.route!.pauseStartedAt = Date().addingTimeInterval(-(RouteService.pauseTimeoutInterval + 1))

    await service.checkAndAutoFinishIfTimedOut()

    #expect(service.isRecording == false)
    #expect(service.route == nil)
  }

  @Test
  func checkAndAutoFinishIfTimedOutPersistsRouteAsFinished() async throws {
    let (service, _, _) = makeServices()
    service.startRoute()
    service.pauseRoute()
    service.route!.pauseStartedAt = Date().addingTimeInterval(-(RouteService.pauseTimeoutInterval + 1))

    await service.checkAndAutoFinishIfTimedOut()

    let routes = try context!.fetch(FetchDescriptor<Route>())
    #expect(routes.count == 1)
    #expect(routes.first?.status == .finished)
    #expect(routes.first?.endedAt != nil)
  }

  // MARK: - startRoute geocoding accuracy

  @Test
  func startRouteSkipsPoorAccuracyLocationForGeocoding() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    service.startRoute()

    let poorLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 100, verticalAccuracy: 10,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(poorLocation)

    await Task.yield()
    await Task.yield()

    #expect(mockGeocoding.geocodedLocations.isEmpty)
    #expect(service.route?.startPlaceName == nil)
  }

  @Test
  func startRouteSkipsNegativeAccuracyLocationForGeocoding() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    service.startRoute()

    let invalidLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: -1, verticalAccuracy: 10,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(invalidLocation)

    await Task.yield()
    await Task.yield()

    #expect(mockGeocoding.geocodedLocations.isEmpty)
    #expect(service.route?.startPlaceName == nil)
  }

  @Test
  func startRouteUsesFirstAccurateLocationAfterPoorOnes() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    service.startRoute()

    let poorLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 200, verticalAccuracy: 10,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    let goodLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.501, longitude: -0.101),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )

    locationService.locationPublisher.send(poorLocation)
    locationService.locationPublisher.send(goodLocation)

    await Task.yield()
    await Task.yield()

    #expect(mockGeocoding.geocodedLocations.count == 1)
    #expect(mockGeocoding.geocodedLocations.first?.horizontalAccuracy == 10)
    #expect(service.route?.startPlaceName == "Test Place")
  }

  @Test
  func startRouteSetsStartPlaceNameFromAccurateLocation() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    service.startRoute()

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

    service.startRoute()

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
      geocodingService: geocodingService ?? GeocodingService()
    )
    return (service, locationService, recorder)
  }
}
