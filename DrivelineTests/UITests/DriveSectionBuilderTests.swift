//
//  DriveSectionBuilderTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

import Testing
import Foundation
@testable import Driveline

@Suite("DriveSectionBuilder")
@MainActor
struct DriveSectionBuilderTests {

  // MARK: - Empty State

  @Test
  func emptyDrivesProducesNoSections() {
    #expect(DriveSectionBuilder.sections(from: [], searchText: "").isEmpty)
  }

  // MARK: - Section Titles

  @Test
  func todayDriveCreatesTodaySection() {
    let sections = DriveSectionBuilder.sections(from: [makeDrive(daysAgo: 0)], searchText: "")
    #expect(sections.count == 1)
    #expect(sections[0].title == "Today")
  }

  @Test
  func yesterdayDriveCreatesYesterdaySection() {
    let sections = DriveSectionBuilder.sections(from: [makeDrive(daysAgo: 1)], searchText: "")
    #expect(sections.count == 1)
    #expect(sections[0].title == "Yesterday")
  }

  @Test
  func routeTwoDaysAgoCreatesDayNameSection() {
    let drive = makeDrive(daysAgo: 2)
    let sections = DriveSectionBuilder.sections(from: [drive], searchText: "")
    let expected = drive.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(sections.count == 1)
    #expect(sections[0].title == expected)
  }

  @Test
  func routeSixDaysAgoStillCreatesDayNameSection() {
    let drive = makeDrive(daysAgo: 6)
    let sections = DriveSectionBuilder.sections(from: [drive], searchText: "")
    let expected = drive.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(sections.count == 1)
    #expect(sections[0].title == expected)
  }

  @Test
  func routeSevenDaysAgoCreatesMonthYearSection() {
    let drive = makeDrive(daysAgo: 7)
    let sections = DriveSectionBuilder.sections(from: [drive], searchText: "")
    let expected = drive.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(sections.count == 1)
    #expect(sections[0].title == expected)
  }

  @Test
  func routeThirtyDaysAgoCreatesMonthYearSection() {
    let drive = makeDrive(daysAgo: 30)
    let sections = DriveSectionBuilder.sections(from: [drive], searchText: "")
    let expected = drive.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(sections.count == 1)
    #expect(sections[0].title == expected)
  }

  // MARK: - Grouping

  @Test
  func drivesOnSameDayAreGroupedIntoOneSection() {
    let morning = makeDrive(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeDrive(name: "Afternoon", daysAgo: 0, hour: 14)
    let sections = DriveSectionBuilder.sections(from: [morning, afternoon], searchText: "")
    #expect(sections.count == 1)
    #expect(sections[0].rows.count == 2)
  }

  @Test
  func drivesOnDifferentDaysProduceSeparateSections() {
    let today = makeDrive(name: "Today", daysAgo: 0)
    let yesterday = makeDrive(name: "Yesterday", daysAgo: 1)
    let older = makeDrive(name: "Older", daysAgo: 10)
    let sections = DriveSectionBuilder.sections(from: [today, yesterday, older], searchText: "")
    #expect(sections.count == 3)
  }

  @Test
  func drivesFromSameOlderMonthAreGroupedIntoOneSection() {
    let a = makeDrive(name: "Drive A", daysAgo: 30, hour: 8)
    let b = makeDrive(name: "Drive B", daysAgo: 30, hour: 14)
    let expectedTitle = a.startedAt.formatted(.dateTime.month(.wide).year())
    let bTitle = b.startedAt.formatted(.dateTime.month(.wide).year())
    if expectedTitle == bTitle {
      let sections = DriveSectionBuilder.sections(from: [a, b], searchText: "")
      #expect(sections.count == 1)
      #expect(sections[0].rows.count == 2)
    }
  }

  // MARK: - Ordering

  @Test
  func sectionsAreOrderedNewestFirst() {
    let today = makeDrive(name: "Today", daysAgo: 0)
    let yesterday = makeDrive(name: "Yesterday", daysAgo: 1)
    let lastWeek = makeDrive(name: "Last Week", daysAgo: 5)
    let sections = DriveSectionBuilder.sections(from: [lastWeek, yesterday, today], searchText: "")
    #expect(sections[0].title == "Today")
    #expect(sections[1].title == "Yesterday")
  }

  @Test
  func drivesWithinSectionAreOrderedNewestFirst() {
    let morning = makeDrive(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeDrive(name: "Afternoon", daysAgo: 0, hour: 14)
    let sections = DriveSectionBuilder.sections(from: [morning, afternoon], searchText: "")
    #expect(sections.count == 1)
    #expect(sections[0].rows[0].drive.displayName == "Afternoon")
    #expect(sections[0].rows[1].drive.displayName == "Morning")
  }

  // MARK: - Search

  @Test
  func emptyQueryShowsAllDrives() {
    let drives = [makeDrive(name: "A", daysAgo: 0), makeDrive(name: "B", daysAgo: 1)]
    let sections = DriveSectionBuilder.sections(from: drives, searchText: "")
    #expect(sections.flatMap(\.rows).count == 2)
  }

  @Test
  func searchByDisplayNameFiltersResults() {
    let drives = [makeDrive(name: "Morning Commute", daysAgo: 0), makeDrive(name: "Evening Run", daysAgo: 0)]
    let sections = DriveSectionBuilder.sections(from: drives, searchText: "Morning")
    let rows = sections.flatMap(\.rows)
    #expect(rows.count == 1)
    #expect(rows[0].drive.displayName == "Morning Commute")
  }

  @Test
  func searchByStartPlaceNameFiltersResults() {
    let match = makeDrive(name: "A", daysAgo: 0)
    match.startPlaceName = "Home"
    let noMatch = makeDrive(name: "B", daysAgo: 0)
    noMatch.startPlaceName = "Office"
    let sections = DriveSectionBuilder.sections(from: [match, noMatch], searchText: "Home")
    let rows = sections.flatMap(\.rows)
    #expect(rows.count == 1)
    #expect(rows[0].drive.id == match.id)
  }

  @Test
  func searchByEndPlaceNameFiltersResults() {
    let match = makeDrive(name: "A", daysAgo: 0)
    match.endPlaceName = "Airport"
    let noMatch = makeDrive(name: "B", daysAgo: 0)
    noMatch.endPlaceName = "Office"
    let sections = DriveSectionBuilder.sections(from: [match, noMatch], searchText: "Airport")
    let rows = sections.flatMap(\.rows)
    #expect(rows.count == 1)
    #expect(rows[0].drive.id == match.id)
  }

  @Test
  func searchIsCaseInsensitive() {
    let sections = DriveSectionBuilder.sections(from: [makeDrive(name: "morning commute", daysAgo: 0)], searchText: "MORNING")
    #expect(sections.flatMap(\.rows).count == 1)
  }

  @Test
  func searchWithNoMatchReturnsEmptySections() {
    let sections = DriveSectionBuilder.sections(from: [makeDrive(name: "Home to Office", daysAgo: 0)], searchText: "zzznomatch")
    #expect(sections.isEmpty)
  }

  @Test
  func emptySearchRestoresAllDrives() {
    let drives = [makeDrive(name: "A", daysAgo: 0), makeDrive(name: "B", daysAgo: 1)]
    #expect(DriveSectionBuilder.sections(from: drives, searchText: "A").flatMap(\.rows).count == 1)
    #expect(DriveSectionBuilder.sections(from: drives, searchText: "").flatMap(\.rows).count == 2)
  }
}

// MARK: - Helpers

private func makeDrive(name: String? = nil, daysAgo: Int, hour: Int = 9) -> Drive {
  let calendar = Calendar.current
  let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
  let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
  let drive = Drive(name: name)
  drive.startedAt = date
  return drive
}
