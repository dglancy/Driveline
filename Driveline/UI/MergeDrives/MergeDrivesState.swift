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
    let result = await service.merge(firstID: firstID, secondID: secondID, mergedName: mergedName) { fraction in
      continuation.yield(fraction)
    }

    continuation.finish()
    await consumer.value
    progress = 1

    guard let result else { return }
    await spotlight.deindexDrives(result.deletedIDs)
    if let merged = fetchDrive(result.mergedID) {
      await spotlight.indexDrive(merged)
    }
  }

  // MARK: - Private

  private func fetchDrive(_ id: UUID) -> Drive? {
    let context = ModelContext(modelContainer)
    let descriptor = FetchDescriptor<Drive>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }
}
