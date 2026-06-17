//
//  DriveMergeService.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import Foundation
import SwiftData

// MARK: - DriveMergeResult

struct DriveMergeResult: Sendable {
  let mergedID: UUID
  let deletedIDs: [UUID]
}

// MARK: - DriveMergeService

@ModelActor
actor DriveMergeService {

  // MARK: - Actions

  /// Merges two drives into a new combined drive in a background context, reporting progress
  /// as positions are re-parented. Spotlight (de)indexing is left to the caller via the
  /// returned identifiers, since the indexing service is `@MainActor`.
  func merge(
    firstID: UUID,
    secondID: UUID,
    mergedName: String,
    onProgress: @Sendable (Double) -> Void
  ) async -> DriveMergeResult? {
    guard let first = drive(forID: firstID), let second = drive(forID: secondID) else { return nil }

    let combinedPositions = positions(forDriveID: firstID) + positions(forDriveID: secondID)

    let merged = Drive(name: mergedName)
    merged.startedAt = first.startedAt
    merged.endedAt = second.endedAt ?? first.endedAt
    merged.status = .finished
    merged.startPlaceName = first.startPlaceName
    merged.endPlaceName = second.endPlaceName
    merged.weatherReadings = [first.startWeather, second.endWeather].compactMap { $0 }
    modelContext.insert(merged)

    let total = combinedPositions.count
    if total == 0 {
      onProgress(1)
    } else {
      let batchSize = Constants.Configuration.driveMergeProgressBatchSize
      for (index, position) in combinedPositions.enumerated() {
        position.drive = merged
        if (index + 1) % batchSize == 0 || index == total - 1 {
          onProgress(Double(index + 1) / Double(total))
          await Task.yield()
        }
      }
    }

    merged.accumulatedDistanceMetres = merged.distanceMetres

    modelContext.delete(first)
    modelContext.delete(second)
    modelContext.saveChanges("drive merge")

    return DriveMergeResult(mergedID: merged.id, deletedIDs: [firstID, secondID])
  }

  // MARK: - Private

  private func drive(forID id: UUID) -> Drive? {
    let descriptor = FetchDescriptor<Drive>(predicate: #Predicate { $0.id == id })
    return try? modelContext.fetch(descriptor).first
  }

  private func positions(forDriveID driveID: UUID) -> [Position] {
    let descriptor = FetchDescriptor<Position>(
      predicate: #Predicate { $0.drive?.id == driveID },
      sortBy: [SortDescriptor(\.timestamp, order: .forward)]
    )
    return (try? modelContext.fetch(descriptor)) ?? []
  }
}
