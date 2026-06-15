//
//  DriveClassifierServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 12/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class DriveClassifierServiceTests: SwiftDataBaseTestCase {

  // MARK: - classify

  @Test
  func classifySetsDriveCategoryFromModelPrediction() async throws {
    let service = DriveClassifierService()
    let drive = Drive(name: "Test")
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)
    context!.insert(drive)
    try context!.save()

    let category = service.classify(DriveClassificationInput(drive: drive))

    #expect(category != .none)
  }

  @Test
  func classifyDoesNotMutateDrive() async throws {
    let service = DriveClassifierService()
    let drive = Drive(name: "Test")
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)
    context!.insert(drive)
    try context!.save()

    _ = service.classify(DriveClassificationInput(drive: drive))

    #expect(drive.category == .none)
  }
}
