//
//  RouteTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
import SwiftData
@testable import AutoRoute

@Suite("Route")
struct RouteTests {

  // MARK: - Initialisation

  @Test func initialisesWithCorrectDefaults() throws {
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

  @Test func initialisesWithBluetoothTrigger() throws {
    let route = Route(name: "School Run", trigger: .bluetooth)
    #expect(route.trigger == .bluetooth)
  }

  @Test func eachRouteHasUniqueID() throws {
    let a = Route(name: "Route A", trigger: .bluetooth)
    let b = Route(name: "Route B", trigger: .bluetooth)
    #expect(a.id != b.id)
  }

  // MARK: - durationSeconds

  @Test func durationWhenRecordingAndNotPaused() throws {
    let route = Route(name: "Test", trigger: .bluetooth)
    // startDate is .now; endDate is nil — duration should be near zero immediately after init
    #expect(route.durationSeconds >= 0)
    #expect(route.durationSeconds < 2)
  }

  @Test func durationUsesEndDateWhenFinished() throws {
    let route = Route(name: "Test", trigger: .bluetooth)
    route.isRecording = false
    route.endedAt = route.startedAt.addingTimeInterval(600)

    #expect(route.durationSeconds == 600)
  }

  @Test func durationSubtractsPausedTime() throws {
    let route = Route(name: "Test", trigger: .bluetooth)
    route.isRecording = false
    route.endedAt = route.startedAt.addingTimeInterval(600)
    route.pausedDurationSeconds = 60

    #expect(route.durationSeconds == 540)
  }

  @Test func durationSubtractsActivePausePeriod() throws {
    let route = Route(name: "Test", trigger: .bluetooth)
    route.isPaused = true
    route.pauseStartedAt = Date.now.addingTimeInterval(-30)
    route.endedAt = route.startedAt.addingTimeInterval(600)

    // active pause of ~30s on top of no accumulated pause
    #expect(route.durationSeconds < 575)
    #expect(route.durationSeconds >= 0)
  }

  @Test func durationIsNeverNegative() throws {
    let route = Route(name: "Test", trigger: .bluetooth)
    route.pausedDurationSeconds = 99999
    #expect(route.durationSeconds == 0)
  }

  // MARK: - Persistence

  @Test @MainActor func persistsAndFetchesRoute() throws {
    let context = ModelContext(try makeTestContainer())

    let route = Route(name: "Coastal Drive", trigger: .bluetooth)
    context.insert(route)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<Route>())
    #expect(fetched.count == 1)
    #expect(fetched[0].name == "Coastal Drive")
  }

  @Test @MainActor func deletingRouteCascadesToPositions() throws {
    let context = ModelContext(try makeTestContainer())

    let route = Route(name: "Test", trigger: .manual)
    context.insert(route)

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
    context.insert(position)
    route.positions.append(position)
    try context.save()

    context.delete(route)
    try context.save()

    #expect(try context.fetch(FetchDescriptor<Route>()).isEmpty)
    #expect(try context.fetch(FetchDescriptor<Position>()).isEmpty)
  }
}
