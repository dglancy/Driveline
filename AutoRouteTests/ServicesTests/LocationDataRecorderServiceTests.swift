//
//  LocationDataRecorderServiceTests.swift
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
final class LocationDataRecorderServiceTests: SwiftDataBaseTestCase {

  // MARK: - Tests

  @Test
  func startCreatesRoute() async throws {
    let route = Route(name: "Test route")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    recorder.startRecording(with: route)

    #expect(recorder.route != nil)
  }

  @Test
  func persistingLocationsAppendsPositions() async throws {
    let route = Route(name: "Test route")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    recorder.startRecording(with: route)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    let routePositions = recorder.route!.orderedPositions.count
    #expect(routePositions == 1)

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 1)
  }

  @Test
  func doesNotPersistLocationsBeforeRecordingStarts() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 0)
  }

  @Test
  func stopEndsRecordingRoute() async throws {
    let route = Route(name: "Test route")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    recorder.startRecording(with: route)
    let startedRoute = recorder.route

    recorder.stopRecording()

    #expect(recorder.route == nil)
    #expect(startedRoute!.isRecording == false)
  }

  @Test
  func doesNotPersistLocationsAfterRecordingStops() async throws {
    let route = Route(name: "Test route")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    recorder.startRecording(with: route)
    recorder.stopRecording()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 0)
  }
}
