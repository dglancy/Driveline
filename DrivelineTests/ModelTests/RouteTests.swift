//
//  RouteTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Testing
import Foundation
import SwiftData

@Suite("Route")
@MainActor
final class RouteTests: SwiftDataBaseTestCase {

  // MARK: - Initialisation

  @Test
  func initialisesWithCorrectDefaults() throws {
    let route = Route(name: "Morning Commute")

    #expect(route.name == "Morning Commute")
    #expect(route.trigger == .manual)
    #expect(route.endedAt == nil)
    #expect(route.startPlaceName == nil)
    #expect(route.endPlaceName == nil)
    #expect(route.isRecording == true)
    #expect(route.isPaused == false)
    #expect(route.pausedDurationSeconds == 0)
    #expect(route.pauseStartedAt == nil)
    #expect(route.positions.isEmpty)
  }

  @Test
  func initialisesWithAutomaticTrigger() throws {
    let route = Route(name: "School Run", trigger: .automatic)
    #expect(route.trigger == .automatic)
  }

  @Test
  func eachRouteHasUniqueID() throws {
    let a = Route(name: "Route A", trigger: .automatic)
    let b = Route(name: "Route B", trigger: .automatic)
    #expect(a.id != b.id)
  }

  // MARK: - Positions
  
  @Test
  func positions() async {
    let route = Route(name: "School Run")
    let base = Date(timeIntervalSinceReferenceDate: 0)

    let p1 = Position(timestamp: base, latitude: 1.0, longitude: 1.0, altitude: 1.0, horizontalAccuracy: 1.0,
                      verticalAccuracy: 1.0, course: 1.0, courseAccuracy: 1.0, speed: 1.0, speedAccuracy: 1.0)
    let p2 = Position(timestamp: base.addingTimeInterval(1), latitude: 1.0, longitude: 1.0, altitude: 1.0,
                      horizontalAccuracy: 1.0, verticalAccuracy: 1.0, course: 1.0, courseAccuracy: 1.0,
                      speed: 1.0, speedAccuracy: 1.0)
    let p3 = Position(timestamp: base.addingTimeInterval(2), latitude: 1.0, longitude: 1.0, altitude: 1.0,
                      horizontalAccuracy: 1.0, verticalAccuracy: 1.0, course: 1.0, courseAccuracy: 1.0,
                      speed: 1.0, speedAccuracy: 1.0)
    route.positions.append(p1)
    route.positions.append(p2)
    route.positions.append(p3)

    let positions = route.orderedPositions
    #expect(positions.count == 3)
    #expect(positions[0] === p1)
    #expect(positions[1] === p2)
    #expect(positions[2] === p3)
  }

  
  // MARK: - activeDurationSeconds

  @Test
  func activeDurationWhenRecordingAndNotPaused() throws {
    let route = Route(name: "Test", trigger: .automatic)
    #expect(route.activeDurationSeconds >= 0)
    #expect(route.activeDurationSeconds < 2)
  }

  @Test
  func activeDurationUsesEndDateWhenFinished() throws {
    let route = Route(name: "Test", trigger: .automatic)
    route.status = .finished
    route.endedAt = route.startedAt.addingTimeInterval(600)

    #expect(route.activeDurationSeconds == 600)
  }

  @Test
  func activeDurationSubtractsPausedTime() throws {
    let route = Route(name: "Test", trigger: .automatic)
    route.status = .finished
    route.endedAt = route.startedAt.addingTimeInterval(600)
    route.pausedDurationSeconds = 60

    #expect(route.activeDurationSeconds == 540)
  }

  @Test
  func activeDurationSubtractsActivePausePeriod() throws {
    let route = Route(name: "Test", trigger: .automatic)
    route.status = .paused
    route.pauseStartedAt = Date.now.addingTimeInterval(-30)
    route.endedAt = route.startedAt.addingTimeInterval(600)

    #expect(route.activeDurationSeconds < 575)
    #expect(route.activeDurationSeconds >= 0)
  }

  @Test
  func activeDurationIsNeverNegative() throws {
    let route = Route(name: "Test", trigger: .automatic)
    route.pausedDurationSeconds = 99999
    #expect(route.activeDurationSeconds == 0)
  }

  // MARK: - Persistence

  @Test
  func freshContainer() async throws {
    let count = try count(where: #Predicate<Position> { _ in
      true
    })
    #expect(count == 0)
  }

  
  @Test
  func persistsAndFetchesRoute() throws {
    let route = Route(name: "Coastal Drive", trigger: .automatic)
    context!.insert(route)
    try context!.save()

    let fetched = try context!.fetch(FetchDescriptor<Route>())
    #expect(fetched.count == 1)
    #expect(fetched[0].name == "Coastal Drive")
  }

  // MARK: - distanceMetres

  @Test
  func distanceMetresIsZeroWithNoPositions() throws {
    let route = Route(name: "Test")
    #expect(route.distanceMetres == 0)
  }

  @Test
  func distanceMetresIsZeroForSinglePosition() throws {
    let route = Route(name: "Test")
    context!.insert(route)
    let p = makePosition(latitude: 51.5, longitude: -0.1)
    context!.insert(p)
    route.positions.append(p)
    #expect(route.distanceMetres == 0)
  }

  @Test
  func distanceMetresCalculatesBetweenTwoPoints() throws {
    let route = Route(name: "Test")
    context!.insert(route)
    // 0.1 degree latitude ≈ 11,132m
    let p1 = makePosition(latitude: 0.0, longitude: 0.0)
    let p2 = makePosition(latitude: 0.1, longitude: 0.0, timestamp: .now.addingTimeInterval(60))
    context!.insert(p1)
    context!.insert(p2)
    route.positions.append(p1)
    route.positions.append(p2)
    #expect(route.distanceMetres > 11_000)
    #expect(route.distanceMetres < 11_500)
  }

  @Test
  func distanceMetresSortsPositionsByTimestamp() throws {
    let route = Route(name: "Test")
    context!.insert(route)
    let t1 = Date.now
    let t2 = t1.addingTimeInterval(60)
    let p1 = makePosition(latitude: 0.0, longitude: 0.0, timestamp: t1)
    let p2 = makePosition(latitude: 0.1, longitude: 0.0, timestamp: t2)
    context!.insert(p1)
    context!.insert(p2)
    route.positions.append(p2)
    route.positions.append(p1)
    #expect(route.distanceMetres > 11_000)
    #expect(route.distanceMetres < 11_500)
  }

  // MARK: - Persistence

  @Test
  func deletingRouteCascadesToPositions() throws {
    let route = Route(name: "Test", trigger: .manual)
    context!.insert(route)

    let position = Position(
      latitude: 51.5,
      longitude: -0.1,
      altitude: 10,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 0,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )
    context!.insert(position)
    route.positions.append(position)
    try context!.save()

    context!.delete(route)
    try context!.save()

    #expect(try context!.fetch(FetchDescriptor<Route>()).isEmpty)
    #expect(try context!.fetch(FetchDescriptor<Position>()).isEmpty)
  }
}
