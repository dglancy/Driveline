//
//  HomeViewModelTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
@testable import Driveline

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {

  // MARK: - Empty State

  @Test
  func emptyDrivesProducesNoSections() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [])
    #expect(viewModel.sections.isEmpty)
  }

  // MARK: - Section Titles

  @Test
  func todayDriveCreatesTodaySection() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == "Today")
  }

  @Test
  func yesterdayDriveCreatesYesterdaySection() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 1)])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == "Yesterday")
  }

  @Test
  func routeTwoDaysAgoCreatesDayNameSection() {
    let viewModel = HomeViewModel()
    let drive = makeDrive(daysAgo: 2)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeSixDaysAgoStillCreatesDayNameSection() {
    let viewModel = HomeViewModel()
    let drive = makeDrive(daysAgo: 6)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeSevenDaysAgoCreatesMonthYearSection() {
    let viewModel = HomeViewModel()
    let drive = makeDrive(daysAgo: 7)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeThirtyDaysAgoCreatesMonthYearSection() {
    let viewModel = HomeViewModel()
    let drive = makeDrive(daysAgo: 30)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  // MARK: - Grouping

  @Test
  func drivesOnSameDayAreGroupedIntoOneSection() {
    let viewModel = HomeViewModel()
    let morning = makeDrive(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeDrive(name: "Afternoon", daysAgo: 0, hour: 14)
    viewModel.update(with: [morning, afternoon])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].rows.count == 2)
  }

  @Test
  func drivesOnDifferentDaysProduceSeparateSections() {
    let viewModel = HomeViewModel()
    let today = makeDrive(name: "Today", daysAgo: 0)
    let yesterday = makeDrive(name: "Yesterday", daysAgo: 1)
    let older = makeDrive(name: "Older", daysAgo: 10)
    viewModel.update(with: [today, yesterday, older])
    #expect(viewModel.sections.count == 3)
  }

  @Test
  func drivesFromSameOlderMonthAreGroupedIntoOneSection() {
    let viewModel = HomeViewModel()
    let a = makeDrive(name: "Drive A", daysAgo: 30, hour: 8)
    let b = makeDrive(name: "Drive B", daysAgo: 30, hour: 14)
    viewModel.update(with: [a, b])

    let expectedTitle = a.startedAt.formatted(.dateTime.month(.wide).year())
    let bTitle = b.startedAt.formatted(.dateTime.month(.wide).year())

    if expectedTitle == bTitle {
      #expect(viewModel.sections.count == 1)
      #expect(viewModel.sections[0].rows.count == 2)
    }
  }

  // MARK: - Ordering

  @Test
  func sectionsAreOrderedNewestFirst() {
    let viewModel = HomeViewModel()
    let today = makeDrive(name: "Today", daysAgo: 0)
    let yesterday = makeDrive(name: "Yesterday", daysAgo: 1)
    let lastWeek = makeDrive(name: "Last Week", daysAgo: 5)
    viewModel.update(with: [lastWeek, yesterday, today])
    #expect(viewModel.sections[0].title == "Today")
    #expect(viewModel.sections[1].title == "Yesterday")
  }

  @Test
  func drivesWithinSectionAreOrderedNewestFirst() {
    let viewModel = HomeViewModel()
    let morning = makeDrive(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeDrive(name: "Afternoon", daysAgo: 0, hour: 14)
    viewModel.update(with: [morning, afternoon])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].rows[0].display.name == "Afternoon")
    #expect(viewModel.sections[0].rows[1].display.name == "Morning")
  }

  // MARK: - Summary Line

  @Test
  func summaryLineIsNilWhenNoDrives() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [])
    #expect(viewModel.summaryLine == nil)
  }

  @Test
  func summaryLineIsNilWhenAllDrivesOlderThan30Days() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 31), makeDrive(daysAgo: 60)])
    #expect(viewModel.summaryLine == nil)
  }

  @Test
  func summaryLineIncludesCountOfDrivesInWindow() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [
      makeDrive(daysAgo: 0),
      makeDrive(daysAgo: 5),
      makeDrive(daysAgo: 31)
    ])
    let summary = try! #require(viewModel.summaryLine)
    #expect(summary.hasPrefix("2 drives"))
  }

  @Test
  func summaryLineUsesSingularForOneDrive() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    let summary = try! #require(viewModel.summaryLine)
    #expect(summary.hasPrefix("1 drive"))
  }

  @Test
  func summaryLineContainsLocalisedDistance() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    let summary = try! #require(viewModel.summaryLine)
    let expectedUnit = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceUnitSymbol()
    #expect(summary.contains("\(expectedUnit) in the last 30 days"))
  }

  @Test
  func summaryLineIsNilAfterUpdateWithNoRecentDrives() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    #expect(viewModel.summaryLine != nil)
    viewModel.update(with: [makeDrive(daysAgo: 60)])
    #expect(viewModel.summaryLine == nil)
  }

  // MARK: - Update

  @Test
  func callingUpdateReplacesPreviousSections() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    #expect(viewModel.sections.count == 1)
    viewModel.update(with: [])
    #expect(viewModel.sections.isEmpty)
  }

  @Test
  func sectionsReflectLatestDriveSet() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeDrive(name: "A", daysAgo: 0)])
    viewModel.update(with: [makeDrive(name: "B", daysAgo: 0), makeDrive(name: "C", daysAgo: 1)])
    #expect(viewModel.sections.count == 2)
    #expect(viewModel.sections[0].rows[0].display.name == "B")
  }
}

// MARK: - Helpers

private func makeDrive(name: String = "Test Drive", daysAgo: Int, hour: Int = 9) -> Drive {
  let calendar = Calendar.current
  let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
  let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
  let drive = Drive(name: name)
  drive.startedAt = date
  return drive
}
