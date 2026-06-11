//
//  DriveDeletionService.swift
//  Driveline
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation
import SwiftData

@MainActor
final class DriveDeletionService {

  // MARK: - Properties

  private let modelContext: ModelContext
  private let spotlightIndexingService: SpotlightIndexingService?

  // MARK: - Lifecycle

  init(modelContext: ModelContext, spotlightIndexingService: SpotlightIndexingService?) {
    self.modelContext = modelContext
    self.spotlightIndexingService = spotlightIndexingService
  }

  // MARK: - Actions

  func delete(_ drives: [Drive]) {
    guard !drives.isEmpty else { return }
    let ids = drives.map(\.id)
    for drive in drives {
      modelContext.delete(drive)
    }
    do {
      try modelContext.save()
    } catch {
      Log.data.error("Failed to delete drives: \(error.localizedDescription)")
    }
    Task { await spotlightIndexingService?.deindexDrives(ids) }
  }
}
