//
//  AutomaticDriveMergeCoordinator.swift
//  Driveline
//
//  Created by Damien Glancy on 11/10/2026.
//

import Foundation
import SwiftData

@MainActor
final class AutomaticDriveMergeCoordinator {

  // MARK: - Properties

  private let modelContainer: ModelContainer
  private let mergeService: DriveMergeService
  private let spotlightIndexingService: SpotlightIndexingService?
  private let categoryPredictionSweepService: CategoryPredictionSweepService
  private var userPreferences: UserPreferences
  private var pendingTask: Task<Void, Never>?

  // MARK: - Lifecycle

  init(
    modelContainer: ModelContainer,
    spotlightIndexingService: SpotlightIndexingService?,
    categoryPredictionSweepService: CategoryPredictionSweepService,
    userPreferences: UserPreferences = UserPreferences()
  ) {
    self.modelContainer = modelContainer
    self.mergeService = DriveMergeService(modelContainer: modelContainer)
    self.spotlightIndexingService = spotlightIndexingService
    self.categoryPredictionSweepService = categoryPredictionSweepService
    self.userPreferences = userPreferences
  }

  // MARK: - Actions

  func requestMerge(containing date: Date, deferred: Bool) {
    pendingTask?.cancel()

    guard deferred else {
      userPreferences.clearPendingAutomaticMerge()
      pendingTask = Task { [weak self] in
        await self?.mergeDay(containing: date)
      }
      return
    }

    let deadline = Date.now.addingTimeInterval(Constants.Configuration.recentDriveInterval)
    userPreferences.setPendingAutomaticMerge(day: date, deadline: deadline)
    schedulePendingMerge(day: date, deadline: deadline)
  }

  func cancelPendingMerge(containing date: Date, calendar: Calendar = .current) {
    guard let pending = userPreferences.pendingAutomaticMerge,
          calendar.isDate(pending.day, inSameDayAs: date) else { return }
    pendingTask?.cancel()
    pendingTask = nil
    userPreferences.clearPendingAutomaticMerge()
  }

  func restorePendingMerge(now: Date = .now) async {
    guard let pending = userPreferences.pendingAutomaticMerge else { return }
    if pending.deadline <= now {
      await processPendingMergeIfDue(now: now)
    } else {
      schedulePendingMerge(day: pending.day, deadline: pending.deadline)
    }
  }

  func processPendingMergeIfDue(now: Date = .now) async {
    guard let pending = userPreferences.pendingAutomaticMerge,
          pending.deadline <= now else { return }
    guard userPreferences.automaticallyMergeSameDayDrives else {
      userPreferences.clearPendingAutomaticMerge()
      return
    }
    await mergeDay(containing: pending.day)
    userPreferences.clearPendingAutomaticMerge()
    pendingTask = nil
  }

  // MARK: - Private

  private func schedulePendingMerge(day: Date, deadline: Date) {
    pendingTask?.cancel()
    pendingTask = Task { [weak self] in
      let delay = max(0, deadline.timeIntervalSinceNow)
      try? await Task.sleep(for: .seconds(delay))
      guard !Task.isCancelled else { return }
      await self?.processPendingMergeIfDue()
    }
  }

  private func mergeDay(containing date: Date) async {
    guard let result = await mergeService.mergeDay(containing: date) else { return }
    await spotlightIndexingService?.deindexDrives(result.deletedIDs)
    await categoryPredictionSweepService.classify(driveID: result.mergedID)

    let context = ModelContext(modelContainer)
    guard let merged = context.model(for: result.mergedID) as? Drive else { return }
    await spotlightIndexingService?.indexDrive(merged)
  }
}
