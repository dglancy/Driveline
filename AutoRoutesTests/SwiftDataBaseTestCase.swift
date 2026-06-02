//
//  SwiftDataBaseTestCase.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoutes
import Foundation
import SwiftData

@MainActor
class SwiftDataBaseTestCase {

  // MARK: - Properties

  var context: ModelContext?

  // MARK: - Common lifecycle

  init() async throws {
    let schema = Schema([Route.self, Position.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    context = ModelContext(container)
  }

  // MARK: - Common functions

  func count<T: PersistentModel>(where predicate: Predicate<T>) throws -> Int {
    let descriptor = FetchDescriptor<T>(predicate: predicate)
    return try context!.fetchCount(descriptor)
  }
}
