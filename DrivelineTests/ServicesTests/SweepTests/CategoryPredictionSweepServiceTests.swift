//
//  CategoryPredictionSweepServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 13/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class CategoryPredictionSweepServiceTests: SwiftDataBaseTestCase {

  // MARK: - sweep

  @Test
  func sweepClassifiesFinishedDrives() async throws {
    let mockClassifier = MockDriveClassifierService()
    let service = makeSweepService(classifierService: mockClassifier)
    let drive = try insertDrive(status: .finished)

    await service.sweep()

    #expect(mockClassifier.classifiedInputs.count == 1)
    let reloaded = try reload(drive)
    #expect(reloaded.category == mockClassifier.categoryToSet)
    #expect(reloaded.categoryModelVersion == Constants.Configuration.driveCategoryModelVersion)
  }

  @Test
  func sweepReclassifiesDrivesWithOutdatedModelVersion() async throws {
    let mockClassifier = MockDriveClassifierService()
    let service = makeSweepService(classifierService: mockClassifier)
    let drive = try insertDrive(status: .finished, category: .urban, categoryModelVersion: Constants.Configuration.driveCategoryModelVersion - 1)

    await service.sweep()

    #expect(mockClassifier.classifiedInputs.count == 1)
    let reloaded = try reload(drive)
    #expect(reloaded.category == mockClassifier.categoryToSet)
    #expect(reloaded.categoryModelVersion == Constants.Configuration.driveCategoryModelVersion)
  }

  @Test
  func sweepSkipsDrivesAlreadyClassifiedWithCurrentModelVersion() async throws {
    let mockClassifier = MockDriveClassifierService()
    let service = makeSweepService(classifierService: mockClassifier)
    try insertDrive(status: .finished, category: .urban, categoryModelVersion: Constants.Configuration.driveCategoryModelVersion)

    await service.sweep()

    #expect(mockClassifier.classifiedInputs.isEmpty)
  }

  @Test
  func sweepSkipsNonFinishedDrives() async throws {
    let mockClassifier = MockDriveClassifierService()
    let service = makeSweepService(classifierService: mockClassifier)
    try insertDrive(status: .recording)

    await service.sweep()

    #expect(mockClassifier.classifiedInputs.isEmpty)
  }

  @Test
  func sweepProcessesMultipleFinishedDrives() async throws {
    let mockClassifier = MockDriveClassifierService()
    let service = makeSweepService(classifierService: mockClassifier)
    try insertDrive(status: .finished)
    try insertDrive(status: .finished)
    try insertDrive(status: .recording)

    await service.sweep()

    #expect(mockClassifier.classifiedInputs.count == 2)
  }

  // MARK: - Cancellation

  @Test
  func sweepDoesNoWorkWhenTaskAlreadyCancelled() async throws {
    let mockClassifier = MockDriveClassifierService()
    let service = makeSweepService(classifierService: mockClassifier)
    try insertDrive(status: .finished)

    let task = Task { await service.sweep() }
    task.cancel()
    await task.value

    #expect(mockClassifier.classifiedInputs.isEmpty)
  }

  // MARK: - Helpers

  private func makeSweepService(classifierService: any DriveClassifierServiceProtocol) -> CategoryPredictionSweepService {
    CategoryPredictionSweepService(modelContainer: container!, classifierService: classifierService)
  }

  @discardableResult
  private func insertDrive(status: Drive.DriveStatus, category: Drive.Category = .none, categoryModelVersion: Int? = nil) throws -> Drive {
    let drive = Drive(trigger: .manual)
    drive.status = status
    drive.category = category
    drive.categoryModelVersion = categoryModelVersion
    context!.insert(drive)
    try context!.save()
    return drive
  }
}
