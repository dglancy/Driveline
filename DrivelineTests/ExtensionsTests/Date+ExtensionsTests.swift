//
//  Date+ExtensionsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Testing

@testable import Driveline

@Suite
struct DateExtensionsTests {

  // Wednesday 8 January 2025 14:30 UTC — no DST offset in en_GB
  private let referenceDate: Date = {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(identifier: "UTC")!
    return cal.date(from: DateComponents(
      timeZone: TimeZone(identifier: "UTC"),
      year: 2025, month: 1, day: 8, hour: 14, minute: 30
    ))!
  }()

  // MARK: - clockString

  @Test("clockString returns HH:mm in en_GB")
  func testClockStringEnGB() {
    #expect(referenceDate.clockString(locale: Locale(identifier: "en_GB")) == "14:30")
  }

  @Test("clockString returns HH:mm in fr_FR")
  func testClockStringFrFR() {
    #expect(referenceDate.clockString(locale: Locale(identifier: "fr_FR")) == "14:30")
  }

  // MARK: - longDateString

  @Test("longDateString returns wide weekday, wide month, and day in en_GB")
  func testLongDateStringEnGB() {
    #expect(referenceDate.longDateString(locale: Locale(identifier: "en_GB")) == "Wednesday 8 January")
  }

  // MARK: - weekdayName

  @Test("weekdayName returns wide weekday in en_GB")
  func testWeekdayNameEnGB() {
    #expect(referenceDate.weekdayName(locale: Locale(identifier: "en_GB")) == "Wednesday")
  }

  // MARK: - monthAndYear

  @Test("monthAndYear returns wide month and year in en_GB")
  func testMonthAndYearEnGB() {
    #expect(referenceDate.monthAndYear(locale: Locale(identifier: "en_GB")) == "January 2025")
  }

  @Test("monthAndYear returns localized wide month in fr_FR")
  func testMonthAndYearFrFR() {
    #expect(referenceDate.monthAndYear(locale: Locale(identifier: "fr_FR")) == "janvier 2025")
  }

  // MARK: - abbreviatedMonthAndDay

  @Test("abbreviatedMonthAndDay returns abbreviated month and day in en_GB")
  func testAbbreviatedMonthAndDayEnGB() {
    #expect(referenceDate.abbreviatedMonthAndDay(locale: Locale(identifier: "en_GB")) == "8 Jan")
  }

  @Test("abbreviatedMonthAndDay returns localized abbreviated month in fr_FR")
  func testAbbreviatedMonthAndDayFrFR() {
    #expect(referenceDate.abbreviatedMonthAndDay(locale: Locale(identifier: "fr_FR")) == "8 janv.")
  }
}
