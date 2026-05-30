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

    #expect(service.currentSpeedMs < 0)
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
    service.endRoute()

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
    service.endRoute()

    #expect(service.isRecording == false)
  }

  @Test
  func endRouteSetsIsPausedToFalse() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    service.endRoute()

    #expect(service.isPaused == false)
  }

  @Test
  func endRouteSetsIsPausedToFalseOnRouteModel() async throws {
    let (service, _, _) = makeServices()

    service.startRoute()
    service.pauseRoute()
    let route = service.route!
    service.endRoute()

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
    service.endRoute()

    #expect(service.currentSpeedMs < 0)
  }

  @Test
  func endRouteWithNoActiveRouteDoesNothing() async throws {
    let (service, _, _) = makeServices()

    service.endRoute()

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
  func currentSpeedMsIsNegativeInitially() async throws {
    let (service, _, _) = makeServices()

    #expect(service.currentSpeedMs < 0)
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
  func currentSpeedMsIsNegativeAfterEndRoute() async throws {
    let (service, locationService, _) = makeServices()

    service.startRoute()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    service.endRoute()

    #expect(service.currentSpeedMs < 0)
  }

  // MARK: - loadRoute

  @Test
  func loadRouteSetsActiveRouteAndStopsServices() async throws {
    let (service, locationService, recorder) = makeServices()

    service.startRoute()
    let existingRoute = Route(name: "Existing route")
    service.loadRoute(existingRoute)

    #expect(service.route?.id == existingRoute.id)
    #expect(locationService.status == .stopped)
    #expect(recorder.route == nil)
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
    route.isRecording = true
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isRecording == true)
  }

  @Test
  func initialRouteWithIsRecordingFalseSetsIsRecordingToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.isRecording = false
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isRecording == false)
  }

  @Test
  func initialRouteWithIsPausedTrueSetsIsPausedToTrue() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.isPaused = true
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isPaused == true)
  }

  @Test
  func initialRouteWithIsPausedFalseSetsIsPausedToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let route = Route(name: "Test")
    route.isPaused = false
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: route)

    #expect(service.isPaused == false)
  }

  // MARK: - Helpers

  private func makeServices() -> (RouteService, LocationService, LocationDataRecorderService) {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)
    return (service, locationService, recorder)
  }
}
