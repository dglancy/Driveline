//
//  HomeViewModelTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Driveline

@Suite("HomeViewModel")
final class HomeViewModelTests: SwiftDataBaseTestCase {

  // MARK: - Empty State

  @Test
  func emptyDrivesProducesNoSections() {
    let viewModel = buildViewModel()
    viewModel.update(with: [])
    #expect(viewModel.sections.isEmpty)
  }

  // MARK: - Section Titles

  @Test
  func todayDriveCreatesTodaySection() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == "Today")
  }

  @Test
  func yesterdayDriveCreatesYesterdaySection() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 1)])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == "Yesterday")
  }

  @Test
  func routeTwoDaysAgoCreatesDayNameSection() {
    let viewModel = buildViewModel()
    let drive = makeDrive(daysAgo: 2)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeSixDaysAgoStillCreatesDayNameSection() {
    let viewModel = buildViewModel()
    let drive = makeDrive(daysAgo: 6)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeSevenDaysAgoCreatesMonthYearSection() {
    let viewModel = buildViewModel()
    let drive = makeDrive(daysAgo: 7)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeThirtyDaysAgoCreatesMonthYearSection() {
    let viewModel = buildViewModel()
    let drive = makeDrive(daysAgo: 30)
    viewModel.update(with: [drive])
    let expected = drive.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  // MARK: - Grouping

  @Test
  func drivesOnSameDayAreGroupedIntoOneSection() {
    let viewModel = buildViewModel()
    let morning = makeDrive(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeDrive(name: "Afternoon", daysAgo: 0, hour: 14)
    viewModel.update(with: [morning, afternoon])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].rows.count == 2)
  }

  @Test
  func drivesOnDifferentDaysProduceSeparateSections() {
    let viewModel = buildViewModel()
    let today = makeDrive(name: "Today", daysAgo: 0)
    let yesterday = makeDrive(name: "Yesterday", daysAgo: 1)
    let older = makeDrive(name: "Older", daysAgo: 10)
    viewModel.update(with: [today, yesterday, older])
    #expect(viewModel.sections.count == 3)
  }

  @Test
  func drivesFromSameOlderMonthAreGroupedIntoOneSection() {
    let viewModel = buildViewModel()
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
    let viewModel = buildViewModel()
    let today = makeDrive(name: "Today", daysAgo: 0)
    let yesterday = makeDrive(name: "Yesterday", daysAgo: 1)
    let lastWeek = makeDrive(name: "Last Week", daysAgo: 5)
    viewModel.update(with: [lastWeek, yesterday, today])
    #expect(viewModel.sections[0].title == "Today")
    #expect(viewModel.sections[1].title == "Yesterday")
  }

  @Test
  func drivesWithinSectionAreOrderedNewestFirst() {
    let viewModel = buildViewModel()
    let morning = makeDrive(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeDrive(name: "Afternoon", daysAgo: 0, hour: 14)
    viewModel.update(with: [morning, afternoon])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].rows[0].drive.displayName == "Afternoon")
    #expect(viewModel.sections[0].rows[1].drive.displayName == "Morning")
  }

  // MARK: - Stats Panel

  @Test
  func recentDriveCountIsZeroWhenNoDrives() {
    let viewModel = buildViewModel()
    viewModel.update(with: [])
    #expect(viewModel.recentStats.driveCount == 0)
  }

  @Test
  func recentDriveCountIsZeroWhenAllDrivesOlderThan30Days() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 31), makeDrive(daysAgo: 60)])
    #expect(viewModel.recentStats.driveCount == 0)
  }

  @Test
  func recentDriveCountReflectsOnlyDrivesWithinWindow() {
    let viewModel = buildViewModel()
    viewModel.update(with: [
      makeDrive(daysAgo: 0),
      makeDrive(daysAgo: 5),
      makeDrive(daysAgo: 31)
    ])
    #expect(viewModel.recentStats.driveCount == 2)
  }

  @Test
  func recentDistanceUnitMatchesLocale() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    let expectedUnit = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceUnitSymbol()
    #expect(viewModel.recentStats.distanceUnit == expectedUnit)
  }

  @Test
  func recentStatsResetWhenUpdatedWithNoRecentDrives() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    #expect(viewModel.recentStats.driveCount == 1)
    viewModel.update(with: [makeDrive(daysAgo: 60)])
    #expect(viewModel.recentStats.driveCount == 0)
  }

  // MARK: - Update

  @Test
  func callingUpdateReplacesPreviousSections() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(daysAgo: 0)])
    #expect(viewModel.sections.count == 1)
    viewModel.update(with: [])
    #expect(viewModel.sections.isEmpty)
  }

  @Test
  func sectionsReflectLatestDriveSet() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(name: "A", daysAgo: 0)])
    viewModel.update(with: [makeDrive(name: "B", daysAgo: 0), makeDrive(name: "C", daysAgo: 1)])
    #expect(viewModel.sections.count == 2)
    #expect(viewModel.sections[0].rows[0].drive.displayName == "B")
  }

  // MARK: - Search

  @Test
  func emptyQueryShowsAllDrives() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(name: "A", daysAgo: 0), makeDrive(name: "B", daysAgo: 1)])
    viewModel.searchText = ""
    #expect(viewModel.sections.flatMap(\.rows).count == 2)
    #expect(viewModel.isSearchActive == false)
  }

  @Test
  func searchByDisplayNameFiltersResults() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(name: "Morning Commute", daysAgo: 0), makeDrive(name: "Evening Run", daysAgo: 0)])
    viewModel.searchText = "Morning"
    let rows = viewModel.sections.flatMap(\.rows)
    #expect(rows.count == 1)
    #expect(rows[0].drive.displayName == "Morning Commute")
    #expect(viewModel.isSearchActive == true)
  }

  @Test
  func searchByStartPlaceNameFiltersResults() {
    let viewModel = buildViewModel()
    let match = makeDrive(name: "A", daysAgo: 0)
    match.startPlaceName = "Home"
    let noMatch = makeDrive(name: "B", daysAgo: 0)
    noMatch.startPlaceName = "Office"
    viewModel.update(with: [match, noMatch])
    viewModel.searchText = "Home"
    let rows = viewModel.sections.flatMap(\.rows)
    #expect(rows.count == 1)
    #expect(rows[0].drive.id == match.id)
  }

  @Test
  func searchByEndPlaceNameFiltersResults() {
    let viewModel = buildViewModel()
    let match = makeDrive(name: "A", daysAgo: 0)
    match.endPlaceName = "Airport"
    let noMatch = makeDrive(name: "B", daysAgo: 0)
    noMatch.endPlaceName = "Office"
    viewModel.update(with: [match, noMatch])
    viewModel.searchText = "Airport"
    let rows = viewModel.sections.flatMap(\.rows)
    #expect(rows.count == 1)
    #expect(rows[0].drive.id == match.id)
  }

  @Test
  func searchIsCaseInsensitive() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(name: "morning commute", daysAgo: 0)])
    viewModel.searchText = "MORNING"
    #expect(viewModel.sections.flatMap(\.rows).count == 1)
  }

  @Test
  func searchWithNoMatchReturnsEmptySections() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(name: "Home to Office", daysAgo: 0)])
    viewModel.searchText = "zzznomatch"
    #expect(viewModel.sections.isEmpty)
  }

  @Test
  func clearingSearchRestoresAllDrives() {
    let viewModel = buildViewModel()
    viewModel.update(with: [makeDrive(name: "A", daysAgo: 0), makeDrive(name: "B", daysAgo: 1)])
    viewModel.searchText = "A"
    #expect(viewModel.sections.flatMap(\.rows).count == 1)
    viewModel.searchText = ""
    #expect(viewModel.sections.flatMap(\.rows).count == 2)
  }

  @Test
  func searchIsPreservedWhenDrivesUpdate() {
    let viewModel = buildViewModel()
    let drive1 = makeDrive(name: "Morning Commute", daysAgo: 0)
    let drive2 = makeDrive(name: "Evening Run", daysAgo: 0)
    viewModel.update(with: [drive1])
    viewModel.searchText = "Morning"
    #expect(viewModel.sections.flatMap(\.rows).count == 1)
    viewModel.update(with: [drive1, drive2])
    #expect(viewModel.sections.flatMap(\.rows).count == 1)
    #expect(viewModel.sections.flatMap(\.rows)[0].drive.displayName == "Morning Commute")
  }

  // MARK: - Select Mode

  @Test
  func isSelectModeFalseOnInitialization() {
    let viewModel = buildViewModel()
    #expect(viewModel.isSelectMode == false)
  }

  @Test
  func sectionsAreEmptyOnInitializationSoSelectButtonIsHidden() {
    let viewModel = buildViewModel()
    #expect(viewModel.sections.isEmpty)
  }

  @Test
  func enterSelectModeSetsIsSelectModeTrue() {
    let viewModel = buildViewModel()
    viewModel.enterSelectMode()
    #expect(viewModel.isSelectMode == true)
  }

  @Test
  func enterSelectModeClearsAnyExistingSelection() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    viewModel.enterSelectMode()
    #expect(viewModel.selectedDriveIDs.isEmpty)
  }

  @Test
  func exitSelectModeSetsIsSelectModeFalse() {
    let viewModel = buildViewModel()
    viewModel.enterSelectMode()
    viewModel.exitSelectMode()
    #expect(viewModel.isSelectMode == false)
  }

  @Test
  func exitSelectModeClearsSelection() {
    let viewModel = buildViewModel()
    viewModel.enterSelectMode()
    viewModel.toggleSelection(for: UUID())
    viewModel.exitSelectMode()
    #expect(viewModel.selectedDriveIDs.isEmpty)
  }

  @Test
  func toggleSelectionAddsIDWhenNotSelected() {
    let viewModel = buildViewModel()
    let id = UUID()
    viewModel.toggleSelection(for: id)
    #expect(viewModel.selectedDriveIDs.contains(id))
  }

  @Test
  func toggleSelectionRemovesIDWhenAlreadySelected() {
    let viewModel = buildViewModel()
    let id = UUID()
    viewModel.toggleSelection(for: id)
    viewModel.toggleSelection(for: id)
    #expect(!viewModel.selectedDriveIDs.contains(id))
  }

  @Test
  func selectedDrivesReturnsOnlySelectedDrives() {
    let viewModel = buildViewModel()
    let drive1 = makeDrive(name: "A", daysAgo: 0)
    let drive2 = makeDrive(name: "B", daysAgo: 1)
    viewModel.update(with: [drive1, drive2])
    viewModel.toggleSelection(for: drive1.id)
    let selected = viewModel.selectedDrives(from: viewModel.sections)
    #expect(selected.count == 1)
    #expect(selected[0].id == drive1.id)
  }

  // MARK: - Computed Properties

  @Test
  func canMergeIsTrueWhenExactlyTwoDrivesSelected() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    viewModel.toggleSelection(for: UUID())
    #expect(viewModel.canMerge == true)
  }

  @Test
  func canMergeIsFalseWithFewerThanTwoDrivesSelected() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    #expect(viewModel.canMerge == false)
  }

  @Test
  func canDeleteIsTrueWhenAtLeastOneDriveIsSelected() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    #expect(viewModel.canDelete == true)
  }

  @Test
  func canDeleteIsFalseWithNoSelection() {
    let viewModel = buildViewModel()
    #expect(viewModel.canDelete == false)
  }

  @Test
  func selectionCountTextShowsPlaceholderWhenNothingSelected() {
    let viewModel = buildViewModel()
    #expect(viewModel.selectionCountText == "Select 2 drives to merge")
  }

  @Test
  func selectionCountTextShowsCountWhenDrivesSelected() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    viewModel.toggleSelection(for: UUID())
    #expect(viewModel.selectionCountText == "2 selected")
  }

  @Test
  func deleteConfirmationMessageIncludesSelectionCount() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    viewModel.toggleSelection(for: UUID())
    viewModel.toggleSelection(for: UUID())
    #expect(viewModel.deleteConfirmationMessage.contains("3"))
  }

  @Test
  func deleteConfirmationMessageUsesSingularForOneDrive() {
    let viewModel = buildViewModel()
    viewModel.toggleSelection(for: UUID())
    #expect(viewModel.deleteConfirmationMessage.contains("1 drive "))
    #expect(!viewModel.deleteConfirmationMessage.contains("1 drives"))
  }

  // MARK: - Trigger Merge

  @Test
  func triggerMergeSetsShowingMergeSheetTrue() {
    let viewModel = buildViewModel()
    let drive1 = makeDrive(name: "A", daysAgo: 0)
    let drive2 = makeDrive(name: "B", daysAgo: 1)
    viewModel.update(with: [drive1, drive2])
    viewModel.toggleSelection(for: drive1.id)
    viewModel.toggleSelection(for: drive2.id)
    viewModel.triggerMerge()
    #expect(viewModel.showingMergeSheet == true)
  }

  @Test
  func triggerMergeSortsDrivesToMergeChronologically() {
    let viewModel = buildViewModel()
    let older = makeDrive(name: "Older", daysAgo: 2)
    let newer = makeDrive(name: "Newer", daysAgo: 0)
    viewModel.update(with: [older, newer])
    viewModel.toggleSelection(for: older.id)
    viewModel.toggleSelection(for: newer.id)
    viewModel.triggerMerge()
    #expect(viewModel.drivesToMerge[0].id == older.id)
    #expect(viewModel.drivesToMerge[1].id == newer.id)
  }

  // MARK: - Delete

  @Test
  func deleteDrivesRemovesDrivesFromContext() throws {
    let drive = insertDrive()
    let viewModel = buildViewModel()
    viewModel.deleteDrives([drive])
    #expect(try count(where: #Predicate<Drive> { _ in true }) == 0)
  }

  @Test
  func deleteDrivesDeindexesFromSpotlight() async throws {
    let mockSpotlight = MockSpotlightIndex()
    let spotlightService = SpotlightIndexingService(index: mockSpotlight)
    let drive = insertDrive()
    let driveID = drive.id
    let viewModel = buildViewModel(spotlight: spotlightService)

    viewModel.deleteDrives([drive])

    await Task.yield()
    await Task.yield()

    #expect(mockSpotlight.deletedIdentifiers == [driveID.uuidString])
  }

  @Test
  func deleteDrivesAtIndexSetRemovesCorrectDrive() throws {
    let drive = insertDrive()
    let viewModel = buildViewModel()
    viewModel.update(with: [drive])
    viewModel.deleteDrives(at: IndexSet([0]), in: viewModel.sections[0])
    #expect(try count(where: #Predicate<Drive> { _ in true }) == 0)
  }

  // MARK: - Merge

  @Test
  func mergeDrivesCreatesOneDriveAndDeletesOriginals() throws {
    let first = insertDrive(name: "First", startOffset: 0, endOffset: 3600)
    let second = insertDrive(name: "Second", startOffset: 3600, endOffset: 7200)
    let viewModel = buildViewModel()
    viewModel.mergeDrives(orderedDrives: [first, second], mergedName: "Merged")
    #expect(try count(where: #Predicate<Drive> { _ in true }) == 1)
  }

  @Test
  func mergeDrivesSetsSuppliedName() throws {
    let first = insertDrive(name: "First", startOffset: 0, endOffset: 3600)
    let second = insertDrive(name: "Second", startOffset: 3600, endOffset: 7200)
    let viewModel = buildViewModel()
    viewModel.mergeDrives(orderedDrives: [first, second], mergedName: "Morning Commute")
    let drives = try context!.fetch(FetchDescriptor<Drive>())
    #expect(drives[0].name == "Morning Commute")
  }

  @Test
  func mergeDrivesSetsDateRangeFromFirstStartToSecondEnd() throws {
    let t0 = Date(timeIntervalSinceReferenceDate: 0)
    let t1 = Date(timeIntervalSinceReferenceDate: 3600)
    let t2 = Date(timeIntervalSinceReferenceDate: 7200)
    let first = insertDrive(name: "First", startOffset: t0.timeIntervalSinceReferenceDate, endOffset: t1.timeIntervalSinceReferenceDate)
    let second = insertDrive(name: "Second", startOffset: t1.timeIntervalSinceReferenceDate, endOffset: t2.timeIntervalSinceReferenceDate)
    let viewModel = buildViewModel()
    viewModel.mergeDrives(orderedDrives: [first, second], mergedName: "Merged")
    let drives = try context!.fetch(FetchDescriptor<Drive>())
    #expect(drives[0].startedAt == t0)
    #expect(drives[0].endedAt == t2)
  }

  @Test
  func mergeDrivesSetsStartAndEndPlaceNames() throws {
    let first = insertDrive(name: "First", startOffset: 0, endOffset: 3600)
    first.startPlaceName = "Home"
    let second = insertDrive(name: "Second", startOffset: 3600, endOffset: 7200)
    second.endPlaceName = "Office"
    let viewModel = buildViewModel()
    viewModel.mergeDrives(orderedDrives: [first, second], mergedName: "Merged")
    let drives = try context!.fetch(FetchDescriptor<Drive>())
    #expect(drives[0].startPlaceName == "Home")
    #expect(drives[0].endPlaceName == "Office")
  }

  @Test
  func mergeDrivesCombinesPositions() throws {
    let first = insertDrive(name: "First", startOffset: 0, endOffset: 3600)
    first.positions = [makePosition(latitude: 1)]
    let second = insertDrive(name: "Second", startOffset: 3600, endOffset: 7200)
    second.positions = [makePosition(latitude: 2), makePosition(latitude: 3)]
    let viewModel = buildViewModel()
    viewModel.mergeDrives(orderedDrives: [first, second], mergedName: "Merged")
    let drives = try context!.fetch(FetchDescriptor<Drive>())
    #expect(drives[0].positions?.count == 3)
  }

  @Test
  func mergeDrivesWithNotTwoDrivesDoesNothing() throws {
    let drive = insertDrive()
    let viewModel = buildViewModel()
    viewModel.mergeDrives(orderedDrives: [drive], mergedName: "Should not merge")
    #expect(try count(where: #Predicate<Drive> { _ in true }) == 1)
  }

  // MARK: - Helpers

  private func insertDrive(name: String = "Test Drive", startOffset: TimeInterval = 0, endOffset: TimeInterval = 3600) -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = Date(timeIntervalSinceReferenceDate: startOffset)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: endOffset)
    context!.insert(drive)
    return drive
  }

  private func makePosition(latitude: Double) -> Position {
    Position(latitude: latitude, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 0, speedAccuracy: 0)
  }

  private func buildViewModel(spotlight: SpotlightIndexingService = SpotlightIndexingService(index: MockSpotlightIndex())) -> HomeViewModel {
    HomeViewModel(spotlightIndexingService: spotlight, modelContext: context!)
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

// MARK: - Drive.displayName

@Suite("Drive.displayName")
@MainActor
struct DriveDisplayNameTests {

  private func makeDrive(hour: Int, name: String? = nil, start: String? = nil, end: String? = nil) -> Drive {
    let calendar = Calendar.current
    let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
    let drive = Drive(name: name)
    drive.startedAt = date
    drive.startPlaceName = start
    drive.endPlaceName = end
    return drive
  }

  @Test func userEditedNameAlwaysWins() {
    let drive = makeDrive(hour: 9, name: "My Commute", start: "Home", end: "Office")
    #expect(drive.displayName == "My Commute")
  }

  @Test func bothPlaceNamesFormatted() {
    let drive = makeDrive(hour: 9, start: "Home", end: "Office")
    #expect(drive.displayName == "Home \u{2192} Office")
  }

  @Test func startOnlyMorning() {
    let drive = makeDrive(hour: 9, start: "Home")
    #expect(drive.displayName == "Morning drive from Home")
  }

  @Test func startOnlyAfternoon() {
    let drive = makeDrive(hour: 14, start: "Home")
    #expect(drive.displayName == "Afternoon drive from Home")
  }

  @Test func startOnlyEvening() {
    let drive = makeDrive(hour: 19, start: "Home")
    #expect(drive.displayName == "Evening drive from Home")
  }

  @Test func startOnlyNight() {
    let drive = makeDrive(hour: 23, start: "Home")
    #expect(drive.displayName == "Night drive from Home")
  }

  @Test func endOnlyMorning() {
    let drive = makeDrive(hour: 9, end: "Office")
    #expect(drive.displayName == "Morning drive to Office")
  }

  @Test func endOnlyEvening() {
    let drive = makeDrive(hour: 19, end: "Office")
    #expect(drive.displayName == "Evening drive to Office")
  }

  @Test func neitherMorning() {
    let drive = makeDrive(hour: 9)
    #expect(drive.displayName == "Morning Drive")
  }

  @Test func neitherAfternoon() {
    let drive = makeDrive(hour: 14)
    #expect(drive.displayName == "Afternoon Drive")
  }

  @Test func neitherEvening() {
    let drive = makeDrive(hour: 19)
    #expect(drive.displayName == "Evening Drive")
  }

  @Test func neitherNight() {
    let drive = makeDrive(hour: 23)
    #expect(drive.displayName == "Night Drive")
  }

  @Test func hourFourIsNight() {
    let drive = makeDrive(hour: 4)
    #expect(drive.displayName == "Night Drive")
  }

  @Test func hourFiveIsMorning() {
    let drive = makeDrive(hour: 5)
    #expect(drive.displayName == "Morning Drive")
  }

  @Test func hourElevenIsMorning() {
    let drive = makeDrive(hour: 11)
    #expect(drive.displayName == "Morning Drive")
  }

  @Test func hourTwelveIsAfternoon() {
    let drive = makeDrive(hour: 12)
    #expect(drive.displayName == "Afternoon Drive")
  }

  @Test func hourSixteenIsAfternoon() {
    let drive = makeDrive(hour: 16)
    #expect(drive.displayName == "Afternoon Drive")
  }

  @Test func hourSeventeenIsEvening() {
    let drive = makeDrive(hour: 17)
    #expect(drive.displayName == "Evening Drive")
  }

  @Test func hourTwentyIsEvening() {
    let drive = makeDrive(hour: 20)
    #expect(drive.displayName == "Evening Drive")
  }

  @Test func hourTwentyOneIsNight() {
    let drive = makeDrive(hour: 21)
    #expect(drive.displayName == "Night Drive")
  }
}

// MARK: - DriveRowDisplay.iconName

@Suite("DriveRowDisplay.iconName")
@MainActor
struct DriveRowDisplayIconTests {

  private func date(hour: Int) -> Date {
    Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now)!
  }

  @Test func hourEightIsMorning() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 8)) == Icons.Drive.morningDrive)
  }

  @Test func hourFourteenIsAfternoon() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 14)) == Icons.Drive.afternoonDrive)
  }

  @Test func hourNineteenIsEvening() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 19)) == Icons.Drive.eveningDrive)
  }

  @Test func hourTwentyThreeIsNight() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 23)) == Icons.Drive.nightDrive)
  }

  @Test func hourThreeIsNight() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 3)) == Icons.Drive.nightDrive)
  }

  @Test func hourFiveIsMorning() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 5)) == Icons.Drive.morningDrive)
  }

  @Test func hourTwelveIsAfternoon() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 12)) == Icons.Drive.afternoonDrive)
  }

  @Test func hourSeventeenIsEvening() {
    #expect(DriveRowDisplay.iconName(for: date(hour: 17)) == Icons.Drive.eveningDrive)
  }
}
