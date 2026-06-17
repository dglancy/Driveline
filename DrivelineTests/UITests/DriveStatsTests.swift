//
//  DriveStatsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

import Testing
import Foundation
@testable import Driveline

@Suite("DriveStats")
@MainActor
struct DriveStatsTests {

  // MARK: - init(drives:)

  @Test
  func emptyDrivesProducesZeroCount() {
    let stats = DriveStats(drives: [])
    #expect(stats.driveCount == 0)
  }

  @Test
  func driveCountMatchesInputCount() {
    let stats = DriveStats(drives: [makeDrive(daysAgo: 0), makeDrive(daysAgo: 1)])
    #expect(stats.driveCount == 2)
  }

  @Test
  func emptyDrivesProducesZeroDistance() {
    let stats = DriveStats(drives: [])
    #expect(stats.totalDistanceMetres == 0)
  }

  @Test
  func totalDistanceAccumulatesDisplayDistances() {
    let drive = makeDrive(daysAgo: 0)
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)
    drive.accumulatedDistanceMetres = 12_345
    let stats = DriveStats(drives: [drive])
    #expect(stats.totalDistanceMetres == 12_345)
  }

  // MARK: - recent(from:)

  @Test
  func recentExcludesDrivesOlderThan30Days() {
    let drives = [makeDrive(daysAgo: 0), makeDrive(daysAgo: 5), makeDrive(daysAgo: 31)]
    let stats = DriveStats.recent(from: drives)
    #expect(stats.driveCount == 2)
  }

  @Test
  func recentIsZeroWhenAllDrivesOlderThan30Days() {
    let drives = [makeDrive(daysAgo: 31), makeDrive(daysAgo: 60)]
    let stats = DriveStats.recent(from: drives)
    #expect(stats.driveCount == 0)
  }

  @Test
  func recentResetsWhenDrivesChange() {
    let stats1 = DriveStats.recent(from: [makeDrive(daysAgo: 0)])
    #expect(stats1.driveCount == 1)
    let stats2 = DriveStats.recent(from: [makeDrive(daysAgo: 60)])
    #expect(stats2.driveCount == 0)
  }

  // MARK: - allTime(from:)

  @Test
  func allTimeIncludesAllDrives() {
    let drives = [makeDrive(daysAgo: 0), makeDrive(daysAgo: 60)]
    let stats = DriveStats.allTime(from: drives)
    #expect(stats.driveCount == 2)
  }

  @Test
  func allTimeCountDiffersFromRecentWhenOldDrivesExist() {
    let drives = [makeDrive(daysAgo: 0), makeDrive(daysAgo: 60)]
    #expect(DriveStats.recent(from: drives).driveCount == 1)
    #expect(DriveStats.allTime(from: drives).driveCount == 2)
  }
}

// MARK: - Helpers

private func makeDrive(daysAgo: Int) -> Drive {
  let calendar = Calendar.current
  let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
  let date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day)!
  let drive = Drive(name: nil)
  drive.startedAt = date
  return drive
}
