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
  nonisolated var taskIdentifier: String { Constants.Configuration.categoryPredictionSweepTaskIdentifier }

  // MARK: - Configuration

  func configure(classifierService: any DriveClassifierServiceProtocol) {
    self.classifierService = classifierService
  }

  // MARK: - Actions

  func sweep() async {
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
      let input = DriveClassificationInput(drive: drive)
      drive.category = await classifierService.classify(input)
      drive.categoryModelVersion = currentModelVersion
      await Task.yield()
    }

    do {
      try modelContext.save()
    } catch {
      Log.data.error("Failed to save model context during debug category prediction sweep: \(error.localizedDescription)")
    }
  }

  // MARK: - Private

  private func resolvedClassifierService() async -> any DriveClassifierServiceProtocol {
    if let classifierService { return classifierService }
    let service = await MainActor.run { DriveClassifierService() }
    classifierService = service
    return service
  }
}
