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
  let mergedID: PersistentIdentifier
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
    driveIDs: [PersistentIdentifier],
    mergedName: String?,
    onProgress: @Sendable (Double) -> Void
  ) async -> DriveMergeResult? {
    let uniqueIDs = Array(Set(driveIDs))
    guard uniqueIDs.count >= 2 else { return nil }
    let drives = uniqueIDs.compactMap { modelContext.model(for: $0) as? Drive }
      .sorted { $0.startedAt < $1.startedAt }
    guard drives.count == uniqueIDs.count, let first = drives.first, let last = drives.last else { return nil }

    let combinedPositions = drives
      .flatMap { positions(forDriveID: $0.id) }
      .sorted { $0.timestamp < $1.timestamp }

    let merged = Drive(name: mergedName)
    merged.startedAt = first.startedAt
    merged.endedAt = last.endedAt ?? first.endedAt
    merged.trigger = drives.contains { $0.trigger == .automatic } ? .automatic : .manual
    merged.status = .finished
    merged.startPlaceName = first.startPlaceName
    merged.endPlaceName = last.endPlaceName
    merged.weatherReadings = [first.startWeather, last.endWeather].compactMap { $0 }
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

    let deletedIDs = drives.map(\.id)
    drives.forEach { modelContext.delete($0) }
    guard modelContext.saveChanges("drive merge") else { return nil }

    return DriveMergeResult(mergedID: merged.persistentModelID, deletedIDs: deletedIDs)
  }

  func mergeDay(
    containing date: Date,
    calendar: Calendar = .current,
    onProgress: @Sendable (Double) -> Void = { _ in }
  ) async -> DriveMergeResult? {
    let interval = calendar.dateInterval(of: .day, for: date)
    guard let interval else { return nil }
    let descriptor = FetchDescriptor<Drive>(
      predicate: #Predicate { $0.startedAt >= interval.start && $0.startedAt < interval.end },
      sortBy: [SortDescriptor(\.startedAt, order: .forward)]
    )
    guard let candidates = try? modelContext.fetch(descriptor) else { return nil }
    let eligible = candidates.filter {
      $0.status == .finished && $0.endedAt.map(interval.contains) == true
    }
    guard eligible.count >= 2 else { return nil }
    return await merge(
      driveIDs: eligible.map(\.persistentModelID),
      mergedName: nil,
      onProgress: onProgress
    )
  }

  // MARK: - Private

  private func positions(forDriveID driveID: UUID) -> [Position] {
    let descriptor = FetchDescriptor<Position>(
      predicate: #Predicate { $0.drive?.id == driveID },
      sortBy: [SortDescriptor(\.timestamp, order: .forward)]
    )
    return (try? modelContext.fetch(descriptor)) ?? []
  }
}
