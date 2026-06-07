//
//  DriveMergeService.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

import Foundation
import SwiftData

@MainActor
final class DriveMergeService {

  // MARK: - Properties

  private let modelContext: ModelContext

  // MARK: - Lifecycle

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  // MARK: - Actions

  func merge(orderedDrives: [Drive], mergedName: String) {
    guard orderedDrives.count == 2 else { return }
    let first = orderedDrives[0]
    let second = orderedDrives[1]

    let merged = Drive(name: mergedName)
    merged.startedAt = first.startedAt
    merged.endedAt = second.endedAt ?? first.endedAt
    merged.status = .finished
    merged.startPlaceName = first.startPlaceName
    merged.endPlaceName = second.endPlaceName
    merged.positions = (first.positions ?? []) + (second.positions ?? [])
    merged.accumulatedDistanceMetres = merged.distanceMetres

    modelContext.insert(merged)
    modelContext.delete(first)
    modelContext.delete(second)
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context: \(error.localizedDescription)")
    }
  }
}
