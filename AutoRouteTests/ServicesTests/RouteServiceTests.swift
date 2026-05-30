//
//  RouteServiceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
import Foundation
import SwiftData
import Testing

@MainActor
final class RouteServiceTests: SwiftDataBaseTestCase {

  // MARK: - Tests

  @Test
  func startRouteCreatesRecordingRoute() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)

    service.startRoute()

    #expect(service.route != nil)
    #expect(service.route!.isRecording == true)
    #expect(locationService.status == .started)
    #expect(recorder.route != nil)
  }

  @Test
  func endRouteStopsRecordingAndPersists() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)

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
  func endRouteWithNoActiveRouteDoesNothing() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)

    service.endRoute()

    #expect(service.route == nil)
  }

  @Test
  func pauseRoutePausesLocationService() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)

    service.startRoute()
    service.pauseRoute()

    #expect(locationService.status == .paused)
  }

  @Test
  func resumeRouteResumesLocationService() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)

    service.startRoute()
    service.pauseRoute()
    service.resumeRoute()

    #expect(locationService.status == .started)
  }

  @Test
  func loadRouteSetsActiveRouteAndStopsServices() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)

    service.startRoute()
    let existingRoute = Route(name: "Existing route")
    service.loadRoute(existingRoute)

    #expect(service.route?.id == existingRoute.id)
    #expect(locationService.status == .stopped)
    #expect(recorder.route == nil)
  }

  @Test
  func initialRouteIsSetOnInit() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let existingRoute = Route(name: "Existing route")
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, initialRoute: existingRoute)

    #expect(service.route?.id == existingRoute.id)
  }
}
