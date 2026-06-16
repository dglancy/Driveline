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

  func reload(_ drive: Drive) throws -> Drive {
    let driveID = drive.id
    let descriptor = FetchDescriptor<Drive>(predicate: #Predicate { $0.id == driveID })
    guard let reloaded = try ModelContext(container!).fetch(descriptor).first else {
      throw TestError.driveNotFound
    }
    return reloaded
  }

  func reload(_ drive: Drive, until predicate: (Drive) -> Bool, timeout: Duration = .seconds(30)) async throws -> Drive {
    let deadline = ContinuousClock.now + timeout
    while true {
      let reloaded = try reload(drive)
      if predicate(reloaded) || ContinuousClock.now >= deadline {
        return reloaded
      }
      try await Task.sleep(for: .milliseconds(20))
    }
  }

  enum TestError: Error {
    case driveNotFound
  }
}
