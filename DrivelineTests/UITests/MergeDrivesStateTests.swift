//
//  MergeDrivesStateTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing
internal import CoreSpotlight

@MainActor
final class MergeDrivesStateTests: SwiftDataBaseTestCase {

  // MARK: - merge

  @Test
  func mergeProducesMergedDriveAndUpdatesSpotlight() async throws {
    let mockSpotlight = MockSpotlightIndex()
    let state = MergeDrivesState(
      modelContainer: container!,
      spotlight: SpotlightIndexingService(index: mockSpotlight)
    )
    let (first, second) = try makeDrivePair()

    await state.merge(firstID: first.id, secondID: second.id, mergedName: "Combined")

    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.name == "Combined")
    #expect(Set(mockSpotlight.deletedIdentifiers) == Set([first.id.uuidString, second.id.uuidString]))
    #expect(mockSpotlight.indexedItems.map(\.uniqueIdentifier) == [merged?.id.uuidString])
  }

  @Test
  func mergeFinishesWithFullProgressAndNotMerging() async throws {
    let state = MergeDrivesState(
      modelContainer: container!,
      spotlight: SpotlightIndexingService(index: MockSpotlightIndex())
    )
    let (first, second) = try makeDrivePair()

    await state.merge(firstID: first.id, secondID: second.id, mergedName: "Combined")

    #expect(state.progress == 1)
    #expect(state.isMerging == false)
  }

  // MARK: - Helpers

  private func makeDrivePair() throws -> (Drive, Drive) {
    let first = Drive(name: "First")
    first.startedAt = Date(timeIntervalSinceReferenceDate: 1000)
    first.endedAt = Date(timeIntervalSinceReferenceDate: 2000)
    first.status = .finished
    let second = Drive(name: "Second")
    second.startedAt = Date(timeIntervalSinceReferenceDate: 3000)
    second.endedAt = Date(timeIntervalSinceReferenceDate: 4000)
    second.status = .finished
    context!.insert(first)
    context!.insert(second)
    try context!.save()
    return (first, second)
  }

  private func fetchMerged(excluding ids: [UUID]) throws -> Drive? {
    let all = try ModelContext(container!).fetch(FetchDescriptor<Drive>())
    return all.first { !ids.contains($0.id) }
  }
}
