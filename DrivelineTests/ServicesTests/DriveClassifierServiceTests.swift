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
    let service = DriveClassifierService(modelContext: context!)
    let drive = Drive(name: "Test")
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)
    context!.insert(drive)
    try context!.save()

    await service.classify(drive)

    #expect(drive.category != .none)
  }

  @Test
  func classifyPersistsUpdatedCategory() async throws {
    let service = DriveClassifierService(modelContext: context!)
    let drive = Drive(name: "Test")
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)
    context!.insert(drive)
    try context!.save()

    await service.classify(drive)

    let descriptor = FetchDescriptor<Drive>()
    let persisted = try context!.fetch(descriptor).first
    #expect(persisted?.category == drive.category)
  }
}
