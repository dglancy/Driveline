//
//  DebugCategoryPredictionSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 13/06/2026.
//

import Foundation
import SwiftData

actor CategoryPredictionSweepService: ModelActor, SweepServiceProtocol {

  // MARK: - Properties

  nonisolated let modelContainer: ModelContainer
  nonisolated let modelExecutor: any ModelExecutor
  private let classifierService: any DriveClassifierServiceProtocol
  nonisolated var taskIdentifier: String { Constants.Configuration.categoryPredictionSweepTaskIdentifier }

  // MARK: - Lifecycle

  init(modelContainer: ModelContainer, classifierService: any DriveClassifierServiceProtocol) {
    self.modelContainer = modelContainer
    let modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    self.classifierService = classifierService
  }

  // MARK: - Actions

  func sweep() async {
    let descriptor = FetchDescriptor<Drive>()
    guard let drives = try? modelContext.fetch(descriptor) else { return }
    let finished = drives.filter { $0.status == .finished }
    guard !finished.isEmpty else { return }

    for drive in finished {
      guard !Task.isCancelled else { return }
      let input = DriveClassificationInput(drive: drive)
      drive.category = await classifierService.classify(input)
    }

    do {
      try modelContext.save()
    } catch {
      Log.data.error("Failed to save model context during debug category prediction sweep: \(error.localizedDescription)")
    }
  }
}
