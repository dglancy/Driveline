//
//  DebugCategoryPredictionSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 13/06/2026.
//

import Foundation
import SwiftData

@ModelActor
actor CategoryPredictionSweepService: SweepServiceProtocol {

  // MARK: - Properties

  private var classifierService: (any DriveClassifierServiceProtocol)?
  private var isSweeping = false
  nonisolated var taskIdentifier: String { Constants.Configuration.categoryPredictionSweepTaskIdentifier }

  // MARK: - Configuration

  func configure(classifierService: any DriveClassifierServiceProtocol) {
    self.classifierService = classifierService
  }

  // MARK: - Actions

  func sweep() async {
    guard !isSweeping else { return }
    isSweeping = true
    defer { isSweeping = false }

    let currentModelVersion = Constants.Configuration.driveCategoryModelVersion
    let descriptor = FetchDescriptor<Drive>()
    guard let drives = try? modelContext.fetch(descriptor) else { return }
    let needsReclassification = drives.filter {
      $0.status == .finished && $0.categoryModelVersion != currentModelVersion
    }
    guard !needsReclassification.isEmpty else { return }

    let classifierService = await resolvedClassifierService()
    for drive in needsReclassification {
      guard !Task.isCancelled else { return }
      await reclassify(drive, using: classifierService)
      await Task.yield()
    }

    modelContext.saveChanges("category prediction sweep")
  }

  func classify(driveID: PersistentIdentifier) async {
    let descriptor = FetchDescriptor<Drive>()
    guard let drive = (try? modelContext.fetch(descriptor))?.first(where: { $0.persistentModelID == driveID }) else { return }
    let classifierService = await resolvedClassifierService()
    await reclassify(drive, using: classifierService)
    modelContext.saveChanges("category prediction sweep")
  }

  // MARK: - Private

  private func reclassify(_ drive: Drive, using classifierService: any DriveClassifierServiceProtocol) async {
    let input = DriveClassificationInput(drive: drive)
    drive.category = await classifierService.classify(input)
    drive.categoryModelVersion = Constants.Configuration.driveCategoryModelVersion
  }

  private func resolvedClassifierService() async -> any DriveClassifierServiceProtocol {
    if let classifierService { return classifierService }
    let service = await MainActor.run { DriveClassifierService() }
    classifierService = service
    return service
  }
}
