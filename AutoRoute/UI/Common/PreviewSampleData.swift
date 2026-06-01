//
//  PreviewSampleData.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import SwiftData

enum PreviewSampleData {

  @MainActor
  static func previewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try! ModelContainer(for: Route.self, configurations: config) // swiftlint:disable:this force_try
  }

  @MainActor
  static func sampleRoute(in context: ModelContext) -> Route {
    let calendar = Calendar.current
    let now = Date.now

    func date(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
      let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
      return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    func position(lat: Double, lon: Double, at timestamp: Date, speed: Double = 14) -> Position {
      let pos = Position(
        timestamp: timestamp,
        latitude: lat, longitude: lon,
        altitude: 50, horizontalAccuracy: 5, verticalAccuracy: 3,
        course: 0, courseAccuracy: 5, speed: speed, speedAccuracy: 1
      )
      context.insert(pos)
      return pos
    }

    let route = Route(name: "Weekend to Tahoe", trigger: .automatic)
    route.startedAt = date(daysAgo: 6, hour: 7, minute: 5)
    route.endedAt = route.startedAt.addingTimeInterval(3 * 3600 + 28 * 60)
    route.status = .finished
    route.startPlaceName = "Home · Sunnyvale"
    route.endPlaceName = "South Lake Tahoe"
    context.insert(route)

    let waypoints: [(Double, Double, Double)] = [
      (37.368, -122.036, 10), (37.450, -121.900, 22), (37.560, -121.750, 28),
      (37.700, -121.500, 31), (37.900, -121.200, 35), (38.100, -120.900, 30),
      (38.300, -120.500, 28), (38.560, -119.980, 15)
    ]
    for (index, (lat, lon, speed)) in waypoints.enumerated() {
      let interval = Double(index) * (3 * 3600 + 28 * 60) / Double(waypoints.count - 1)
      let timestamp = route.startedAt.addingTimeInterval(interval)
      route.positions.append(position(lat: lat, lon: lon, at: timestamp, speed: speed))
    }

    return route
  }

  @MainActor
  static func insertSampleRoutes(in context: ModelContext) {
    let calendar = Calendar.current
    let now = Date.now

    func date(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
      let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
      return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    func pos(lat: Double, lon: Double, at timestamp: Date) -> Position {
      let position = Position(
        timestamp: timestamp,
        latitude: lat, longitude: lon,
        altitude: 50, horizontalAccuracy: 5, verticalAccuracy: 3,
        course: 0, courseAccuracy: 5, speed: 14, speedAccuracy: 1
      )
      context.insert(position)
      return position
    }

    typealias Coords = (lat: Double, lon: Double)
    let home: Coords = (51.440, -0.102)

    let samples: [(name: String, daysAgo: Int, hour: Int, minute: Int, duration: TimeInterval?,
                   place: String?, end: Coords?)] = [
      ("Morning Commute", 0, 8, 12, 1_740, "Home", (51.514, -0.093)),
      ("School Run", 0, 15, 30, nil, nil, nil),
      ("Evening Errand", 1, 18, 45, 1_200, "Tesco Extra", (51.452, -0.091)),
      ("Lunch Drive", 3, 12, 20, 2_100, nil, (51.459, -0.119)),
      ("School Run", 3, 8, 10, 840, "School", (51.549, -0.122)),
      ("Weekend Road Trip", 6, 10, 0, 14_400, "Brighton", (50.820, -0.142)),
      ("City Centre Visit", 32, 11, 30, 2_700, "Manchester", (53.480, -2.244)),
      ("Mountain Drive", 68, 9, 0, 10_800, "Snowdonia", (53.120, -4.131))
    ]

    for (name, daysAgo, hour, minute, duration, place, end) in samples {
      let route = Route(name: name)
      route.startedAt = date(daysAgo: daysAgo, hour: hour, minute: minute)
      route.startPlaceName = place
      if let duration {
        route.endedAt = route.startedAt.addingTimeInterval(duration)
        route.status = .finished
      }
      context.insert(route)
      route.positions.append(pos(lat: home.lat, lon: home.lon, at: route.startedAt))
      if let end {
        let endTime = route.endedAt ?? route.startedAt.addingTimeInterval(1_800)
        route.positions.append(pos(lat: end.lat, lon: end.lon, at: endTime))
      }
    }
  }
}
