//
//  DriveDeletionTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 11/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class DriveDeletionTests: SwiftDataBaseTestCase {

  // MARK: - delete(_:)

  @Test
  func deleteRemovesDrivesFromContext() throws {
    let drive = insertDrive()
    DriveDeletion.delete([drive], in: context!, deindexing: SpotlightIndexingService())
    #expect(try count(where: #Predicate<Drive> { _ in true }) == 0)
  }

  @Test
  func deleteDeindexesDrivesFromSpotlight() async throws {
    let mockSpotlight = MockSpotlightIndex()
    let spotlightService = SpotlightIndexingService(index: mockSpotlight)
    let drive = insertDrive()
    let driveID = drive.id

    DriveDeletion.delete([drive], in: context!, deindexing: spotlightService)

    await Task.yield()
    await Task.yield()

    #expect(mockSpotlight.deletedIdentifiers == [driveID.uuidString])
  }

  @Test
  func deleteWithEmptyArrayDoesNothing() throws {
    insertDrive()
    DriveDeletion.delete([], in: context!, deindexing: SpotlightIndexingService())
    #expect(try count(where: #Predicate<Drive> { _ in true }) == 1)
  }

  // MARK: - Helpers

  @discardableResult
  private func insertDrive() -> Drive {
    let drive = Drive(name: "Test Drive", trigger: .manual)
    drive.status = .finished
    drive.startedAt = .now
    drive.endedAt = .now
    context!.insert(drive)
    return drive
  }
}
