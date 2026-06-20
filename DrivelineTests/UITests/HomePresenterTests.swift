//
//  HomePresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

import Testing
import Foundation
@testable import Driveline

@Suite("HomePresenter")
@MainActor
struct HomePresenterTests {

  // MARK: - statsScopeLabel

  @Test
  func statsScopeLabelForLast30Days() {
    #expect(HomePresenter.statsScopeLabel(.last30Days) == "last 30 days")
  }

  @Test
  func statsScopeLabelForAllTime() {
    #expect(HomePresenter.statsScopeLabel(.allTime) == "all time")
  }

  // MARK: - selectionCountText

  @Test
  func selectionCountTextShowsPlaceholderWhenZero() {
    #expect(HomePresenter.selectionCountText(0) == "Select 2 drives to merge")
  }

  @Test
  func selectionCountTextShowsCountWhenSelected() {
    #expect(HomePresenter.selectionCountText(2) == "2 selected")
  }

  @Test
  func selectionCountTextShowsCorrectCount() {
    #expect(HomePresenter.selectionCountText(1) == "1 selected")
    #expect(HomePresenter.selectionCountText(5) == "5 selected")
  }

  // MARK: - deleteConfirmationMessage

  @Test
  func deleteConfirmationMessageIncludesCount() {
    #expect(HomePresenter.deleteConfirmationMessage(3).contains("3"))
  }

  @Test
  func deleteConfirmationMessageIncludesOneDriveForSingular() {
    let message = HomePresenter.deleteConfirmationMessage(1)
    #expect(message.contains("1 drive"))
    #expect(!message.contains("1 drives"))
  }

  @Test func newDriveButtonTitleIsNonEmpty() {
    #expect(!HomePresenter.newDriveButtonTitle.isEmpty)
  }

  @Test func automationSetupTitleIsNonEmpty() {
    #expect(!HomePresenter.automationSetupTitle.isEmpty)
  }

  @Test func automationSetupSubtitleIsNonEmpty() {
    #expect(!HomePresenter.automationSetupSubtitle.isEmpty)
  }
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
