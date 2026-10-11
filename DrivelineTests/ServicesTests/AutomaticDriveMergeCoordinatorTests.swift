//
//  AutomaticDriveMergeCoordinatorTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 11/10/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class AutomaticDriveMergeCoordinatorTests: SwiftDataBaseTestCase {

  // MARK: - Scheduling

  @Test
  func deferredRequestPersistsThirtyMinuteDeadlineWithoutMerging() async throws {
    let (preferences, _) = makePreferences(automaticMerge: true, continueRecent: true)
    let coordinator = await makeCoordinator(preferences: preferences)
    let drives = try insertDrivePair()
    let requestedAt = Date.now

    coordinator.requestMerge(containing: drives.0.startedAt, deferred: true)
    await Task.yield()

    let pending = try #require(preferences.pendingAutomaticMerge)
    #expect(pending.day == drives.0.startedAt)
    #expect(pending.deadline.timeIntervalSince(requestedAt) >= Constants.Configuration.recentDriveInterval - 1)
    #expect(try freshContext().fetchCount(FetchDescriptor<Drive>()) == 2)
  }

  @Test
  func cancellingPendingMergeForSameDayClearsPersistedRequest() async throws {
    let (preferences, _) = makePreferences(automaticMerge: true, continueRecent: true)
    let coordinator = await makeCoordinator(preferences: preferences)
    let drives = try insertDrivePair()
    coordinator.requestMerge(containing: drives.0.startedAt, deferred: true)

    coordinator.cancelPendingMerge(containing: drives.0.startedAt)

    #expect(preferences.pendingAutomaticMerge == nil)
    #expect(try freshContext().fetchCount(FetchDescriptor<Drive>()) == 2)
  }

  @Test
  func duePendingRequestMergesAndClearsPersistedRequest() async throws {
    let (preferences, _) = makePreferences(automaticMerge: true, continueRecent: true)
    let coordinator = await makeCoordinator(preferences: preferences)
    let drives = try insertDrivePair()
    coordinator.requestMerge(containing: drives.0.startedAt, deferred: true)

    await coordinator.processPendingMergeIfDue(
      now: Date.now.addingTimeInterval(Constants.Configuration.recentDriveInterval + 1)
    )

    #expect(preferences.pendingAutomaticMerge == nil)
    #expect(try freshContext().fetchCount(FetchDescriptor<Drive>()) == 1)
  }

  @Test
  func duePendingRequestIsDiscardedWhenAutomaticMergingIsDisabled() async throws {
    let (preferences, defaults) = makePreferences(automaticMerge: true, continueRecent: true)
    let coordinator = await makeCoordinator(preferences: preferences)
    let drives = try insertDrivePair()
    coordinator.requestMerge(containing: drives.0.startedAt, deferred: true)
    defaults.set(false, forKey: "AutomaticallyMergeSameDayDrives")

    await coordinator.processPendingMergeIfDue(
      now: Date.now.addingTimeInterval(Constants.Configuration.recentDriveInterval + 1)
    )

    #expect(preferences.pendingAutomaticMerge == nil)
    #expect(try freshContext().fetchCount(FetchDescriptor<Drive>()) == 2)
  }

  @Test
  func restoreProcessesExpiredPersistedRequest() async throws {
    var (preferences, _) = makePreferences(automaticMerge: true, continueRecent: true)
    let drives = try insertDrivePair()
    preferences.setPendingAutomaticMerge(
      day: drives.0.startedAt,
      deadline: .now.addingTimeInterval(-1)
    )
    let coordinator = await makeCoordinator(preferences: preferences)

    await coordinator.restorePendingMerge()

    let count = try await waitForDriveCount(1)
    #expect(count == 1)
    #expect(preferences.pendingAutomaticMerge == nil)
  }

  // MARK: - Helpers

  private func makeCoordinator(preferences: UserPreferences) async -> AutomaticDriveMergeCoordinator {
    let categoryService = CategoryPredictionSweepService(modelContainer: container!)
    await categoryService.configure(classifierService: MockDriveClassifierService())
    return AutomaticDriveMergeCoordinator(
      modelContainer: container!,
      spotlightIndexingService: nil,
      categoryPredictionSweepService: categoryService,
      userPreferences: preferences
    )
  }

  private func makePreferences(
    automaticMerge: Bool,
    continueRecent: Bool
  ) -> (UserPreferences, UserDefaults) {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    defaults.set(automaticMerge, forKey: "AutomaticallyMergeSameDayDrives")
    defaults.set(continueRecent, forKey: "ContinueDriveIfRecentlyFinished")
    return (UserPreferences(defaults: defaults), defaults)
  }

  private func insertDrivePair() throws -> (Drive, Drive) {
    let first = Drive(name: "First")
    first.startedAt = .now.addingTimeInterval(-120)
    first.endedAt = .now.addingTimeInterval(-60)
    first.status = .finished
    let second = Drive(name: "Second")
    second.startedAt = .now.addingTimeInterval(-50)
    second.endedAt = .now
    second.status = .finished
    context!.insert(first)
    context!.insert(second)
    try context!.save()
    return (first, second)
  }

  private func freshContext() -> ModelContext {
    ModelContext(container!)
  }

  private func waitForDriveCount(_ expectedCount: Int) async throws -> Int {
    for _ in 0..<100 {
      let count = try freshContext().fetchCount(FetchDescriptor<Drive>())
      if count == expectedCount { return count }
      await Task.yield()
    }
    return try freshContext().fetchCount(FetchDescriptor<Drive>())
  }
}
