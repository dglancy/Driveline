//
//  HomeStatsPresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

import Testing
import Foundation
@testable import Driveline

@Suite("HomeStatsPresenter")
@MainActor
struct HomeStatsPresenterTests {

  @Test
  func driveCountPassesThroughStats() {
    let stats = DriveStats(drives: [makeDrive(daysAgo: 0), makeDrive(daysAgo: 1)])
    let presenter = HomeStatsPresenter(stats: stats)
    #expect(presenter.driveCount == 2)
  }

  @Test
  func distanceUnitMatchesLocale() {
    let stats = DriveStats(drives: [makeDrive(daysAgo: 0)])
    let presenter = HomeStatsPresenter(stats: stats)
    let expected = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceUnitSymbol()
    #expect(presenter.distanceUnit == expected)
  }

  @Test
  func distanceValueFormatsTotalDistance() {
    let drive = makeDrive(daysAgo: 0)
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)
    drive.accumulatedDistanceMetres = 12_345
    let presenter = HomeStatsPresenter(stats: DriveStats(drives: [drive]))
    let expected = Measurement(value: 12_345, unit: UnitLength.meters).localizedDistanceValueString()
    #expect(presenter.distanceValue == expected)
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
