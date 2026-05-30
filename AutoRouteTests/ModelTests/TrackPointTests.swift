//
//  TrackPointTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
import SwiftData
@testable import AutoRoute

@Suite("TrackPoint")
struct TrackPointTests {

  // MARK: - Initialisation

  @Test func initialisesWithProvidedValues() throws {
    let timestamp = Date(timeIntervalSinceReferenceDate: 0)
    let point = TrackPoint(
      timestamp: timestamp,
      latitude: 51.5074,
      longitude: -0.1278,
      altitude: 11.5,
      speed: 13.8,
      horizontalAccuracy: 4.0
    )

    #expect(point.timestamp == timestamp)
    #expect(point.latitude == 51.5074)
    #expect(point.longitude == -0.1278)
    #expect(point.altitude == 11.5)
    #expect(point.speed == 13.8)
    #expect(point.horizontalAccuracy == 4.0)
    #expect(point.route == nil)
  }

  @Test func acceptsNegativeSpeedForUnavailable() throws {
    let point = TrackPoint(timestamp: .now, latitude: 0, longitude: 0, altitude: 0, speed: -1, horizontalAccuracy: 10)
    #expect(point.speed < 0)
  }

  // MARK: - Persistence

  @Test @MainActor func persistsAndFetchesPoint() throws {
    let context = try makeTestContainer().mainContext

    let point = TrackPoint(
      timestamp: .now,
      latitude: 53.3498,
      longitude: -6.2603,
      altitude: 20.0,
      speed: 8.3,
      horizontalAccuracy: 6.0
    )
    context.insert(point)
    try context.save()

    let fetched = try context.fetch(FetchDescriptor<TrackPoint>())
    #expect(fetched.count == 1)
    #expect(fetched[0].latitude == 53.3498)
    #expect(fetched[0].longitude == -6.2603)
  }

  @Test @MainActor func associatesWithRoute() throws {
    let context = try makeTestContainer().mainContext

    let route = Route(name: "Evening Drive", trigger: .bluetooth)
    context.insert(route)

    let point = TrackPoint(timestamp: .now, latitude: 51.5, longitude: -0.1, altitude: 5, speed: 10, horizontalAccuracy: 8)
    context.insert(point)
    route.trackPoints.append(point)
    try context.save()

    let fetchedRoute = try context.fetch(FetchDescriptor<Route>()).first!
    #expect(fetchedRoute.trackPoints.count == 1)
    #expect(fetchedRoute.trackPoints.first?.latitude == 51.5)
  }

  @Test @MainActor func multiplePointsAssociateWithOneRoute() throws {
    let context = try makeTestContainer().mainContext
    
    let route = Route(name: "Long Drive", trigger: .manual)
    context.insert(route)

    for i in 0..<5 {
      let point = TrackPoint(
        timestamp: .now.addingTimeInterval(Double(i)),
        latitude: 51.5 + Double(i) * 0.001,
        longitude: -0.1,
        altitude: 0,
        speed: 10,
        horizontalAccuracy: 5
      )
      context.insert(point)
      route.trackPoints.append(point)
    }
    try context.save()

    let fetchedRoute = try context.fetch(FetchDescriptor<Route>()).first!
    #expect(fetchedRoute.trackPoints.count == 5)
  }
}
