//
//  SwiftDataBaseTestCase.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Foundation
import SwiftData

@MainActor
class SwiftDataBaseTestCase {

  // MARK: - Properties

  var context: ModelContext?
  var container: ModelContainer?

  // MARK: - Common lifecycle

  init() async throws {
    let schema = Schema([Drive.self, Position.self, Weather.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    self.container = container
    context = ModelContext(container)
  }

  // MARK: - Common functions

  func count<T: PersistentModel>(where predicate: Predicate<T>) throws -> Int {
    let descriptor = FetchDescriptor<T>(predicate: predicate)
    return try context!.fetchCount(descriptor)
  }

  /// Fetches a fresh copy of `drive` from a new `ModelContext`, reflecting any changes saved by
  /// other contexts (e.g. a `@ModelActor` sweep service's own context) since it was fetched.
  func reload(_ drive: Drive) throws -> Drive {
    let driveID = drive.id
    let descriptor = FetchDescriptor<Drive>(predicate: #Predicate { $0.id == driveID })
    guard let reloaded = try ModelContext(container!).fetch(descriptor).first else {
      throw TestError.driveNotFound
    }
    return reloaded
  }

  enum TestError: Error {
    case driveNotFound
  }
}
