//
//  ModelTestHelpers.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import SwiftData
@testable import AutoRoute

func makeTestContainer() throws -> ModelContainer {
  let schema = Schema([Route.self, Position.self])
  let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  return try ModelContainer(for: schema, configurations: [config])
}

func makePosition(latitude: Double, longitude: Double, timestamp: Date = .now) -> Position {
  Position(
    latitude: latitude,
    longitude: longitude,
    altitude: 50,
    horizontalAccuracy: 5,
    verticalAccuracy: 3,
    course: 0,
    courseAccuracy: 5,
    speed: 14,
    speedAccuracy: 1
  )
}
