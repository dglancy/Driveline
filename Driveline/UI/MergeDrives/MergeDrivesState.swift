//
//  MergeDrivesState.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class MergeDrivesState {

  // MARK: - Properties

  private(set) var isMerging = false
  private(set) var progress: Double = 0

  @ObservationIgnored private let modelContainer: ModelContainer
  @ObservationIgnored private let spotlight: SpotlightIndexingService

  // MARK: - Lifecycle

  init(modelContainer: ModelContainer, spotlight: SpotlightIndexingService) {
    self.modelContainer = modelContainer
    self.spotlight = spotlight
  }

  // MARK: - Actions

  func merge(firstID: UUID, secondID: UUID, mergedName: String) async {
    guard !isMerging else { return }
    isMerging = true
    defer { isMerging = false }

    progress = 0
    let (stream, continuation) = AsyncStream<Double>.makeStream()
    let consumer = Task { @MainActor in
      for await value in stream { progress = value }
    }

    let service = DriveMergeService(modelContainer: modelContainer)
    let context = ModelContext(modelContainer)
    guard let first = fetchDrive(firstID, in: context), let second = fetchDrive(secondID, in: context) else {
      continuation.finish()
      await consumer.value
      return
    }
    let result = await service.merge(
      driveIDs: [first.persistentModelID, second.persistentModelID],
      mergedName: mergedName
    ) { fraction in
      continuation.yield(fraction)
    }

    continuation.finish()
    await consumer.value
    progress = 1

    guard let result else { return }
    await spotlight.deindexDrives(result.deletedIDs)
    if let merged = ModelContext(modelContainer).model(for: result.mergedID) as? Drive {
      await spotlight.indexDrive(merged)
    }
  }

  // MARK: - Private

  private func fetchDrive(_ id: UUID, in context: ModelContext) -> Drive? {
    let descriptor = FetchDescriptor<Drive>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }
}
