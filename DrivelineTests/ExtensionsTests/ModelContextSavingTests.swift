//
//  ModelContextSavingTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class ModelContextSavingTests: SwiftDataBaseTestCase {

  // MARK: - saveChanges

  @Test
  func saveChangesPersistsPendingChangesAndReturnsTrue() throws {
    context!.insert(Drive(name: "Test drive"))
    #expect(context!.hasChanges)

    let saved = context!.saveChanges()

    #expect(saved)
    #expect(!context!.hasChanges)
    let driveCount = try count(where: #Predicate<Drive> { _ in true })
    #expect(driveCount == 1)
  }

  @Test
  func saveChangesIsNoOpAndReturnsTrueWhenNothingChanged() {
    #expect(!context!.hasChanges)

    let saved = context!.saveChanges()

    #expect(saved)
  }
}
