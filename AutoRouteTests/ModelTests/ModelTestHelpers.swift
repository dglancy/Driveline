//
//  ModelTestHelpers.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftData
@testable import AutoRoute

func makeTestContainer() throws -> ModelContainer {
  let schema = Schema([Route.self, Position.self])
  let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
  return try ModelContainer(for: schema, configurations: [config])
}
