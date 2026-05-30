//
//  PositionTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
import SwiftData
@testable import AutoRoute

@Suite("Position")
struct PositionTests {

  // MARK: - Initialisation

  @Test func initialisesWithProvidedValues() throws {
    let timestamp = Date(timeIntervalSinceReferenceDate: 0)
    let position = Position(
      timestamp: timestamp,
      latitude: 51.5074,
      longitude: -0.1278,
      altitude: 11.5,
      horizontalAccuracy: 4.0,
      verticalAccuracy: 3.0,
      course: 270.0,
      courseAccuracy: 5.0,
      speed: 13.8,
      speedAccuracy: 1.0
    )

    #expect(position.timestamp == timestamp)
    #expect(position.latitude == 51.5074)
    #expect(position.longitude == -0.1278)
    #expect(position.altitude == 11.5)
    #expect(position.horizontalAccuracy == 4.0)
    #expect(position.verticalAccuracy == 3.0)
    #expect(position.course == 270.0)
    #expect(position.courseAccuracy == 5.0)
    #expect(position.speed == 13.8)
    #expect(position.speedAccuracy == 1.0)
    #expect(position.route == nil)
  }

  @Test func acceptsNegativeValuesForUnavailableFields() throws {
    let position = Position(
      latitude: 0,
      longitude: 0,
      altitude: 0,
      horizontalAccuracy: -1,
      verticalAccuracy: -1,
      course: -1,
      courseAccuracy: -1,
      speed: -1,
      speedAccuracy: -1
    )
    #expect(position.horizontalAccuracy < 0)
    #expect(position.verticalAccuracy < 0)
    #expect(position.course < 0)
    #expect(position.courseAccuracy < 0)
    #expect(position.speed < 0)
    #expect(position.speedAccuracy < 0)
  }

  // MARK: - Persistence

  @Test @MainActor func persistsAndFetchesPosition() throws {
    let context = ModelContext(try makeTestContainer())

    let position = Position(
      latitude: 53.3498,
      longitude: -6.2603,
      altitude: 20.0,
      horizontalAccuracy: 6.0,
      verticalAccuracy: 3.0,
      course: 90.0,
      courseAccuracy: 5.0,
      speed: 8.3,
      speedAccuracy: 1.0
    )
    context.insert(position)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<Position>())
    #expect(fetched.count == 1)
    #expect(fetched[0].latitude == 53.3498)
    #expect(fetched[0].longitude == -6.2603)
  }

  @Test @MainActor func associatesWithRoute() throws {
    let context = ModelContext(try makeTestContainer())

    let route = Route(name: "Evening Drive", trigger: .bluetooth)
    context.insert(route)

    let position = Position(
      latitude: 51.5,
      longitude: -0.1,
      altitude: 5,
      horizontalAccuracy: 8,
      verticalAccuracy: 3,
      course: 180,
      courseAccuracy: 5,
      speed: 10,
      speedAccuracy: 1
    )
    context.insert(position)
    route.positions.append(position)
    try context.save()

    let fetchedRoute = try context.fetch(FetchDescriptor<Route>()).first!
    #expect(fetchedRoute.positions.count == 1)
    #expect(fetchedRoute.positions.first?.latitude == 51.5)
  }

  @Test @MainActor func multiplePositionsAssociateWithOneRoute() throws {
    let context = ModelContext(try makeTestContainer())

    let route = Route(name: "Long Drive", trigger: .manual)
    context.insert(route)

    for i in 0..<5 {
      let position = Position(
        timestamp: .now.addingTimeInterval(Double(i)),
        latitude: 51.5 + Double(i) * 0.001,
        longitude: -0.1,
        altitude: 0,
        horizontalAccuracy: 5,
        verticalAccuracy: 3,
        course: 0,
        courseAccuracy: 5,
        speed: 10,
        speedAccuracy: 1
      )
      context.insert(position)
      route.positions.append(position)
    }
    try context.save()

    let fetchedRoute = try context.fetch(FetchDescriptor<Route>()).first!
    #expect(fetchedRoute.positions.count == 5)
  }
}
