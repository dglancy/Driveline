//
//  Date+ExtensionsTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Testing

@testable import AutoRoute

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

  // MARK: - clockTime

  @Test("clockTime returns HH:mm in en_GB")
  func testClockTimeEnGB() {
    #expect(referenceDate.clockTime(locale: Locale(identifier: "en_GB")) == "14:30")
  }

  @Test("clockTime returns HH:mm in fr_FR")
  func testClockTimeFrFR() {
    #expect(referenceDate.clockTime(locale: Locale(identifier: "fr_FR")) == "14:30")
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

  @Test("monthAndYear returns localised wide month in fr_FR")
  func testMonthAndYearFrFR() {
    #expect(referenceDate.monthAndYear(locale: Locale(identifier: "fr_FR")) == "janvier 2025")
  }

  // MARK: - abbreviatedMonthAndDay

  @Test("abbreviatedMonthAndDay returns abbreviated month and day in en_GB")
  func testAbbreviatedMonthAndDayEnGB() {
    #expect(referenceDate.abbreviatedMonthAndDay(locale: Locale(identifier: "en_GB")) == "8 Jan")
  }

  @Test("abbreviatedMonthAndDay returns localised abbreviated month in fr_FR")
  func testAbbreviatedMonthAndDayFrFR() {
    #expect(referenceDate.abbreviatedMonthAndDay(locale: Locale(identifier: "fr_FR")) == "8 janv.")
  }
}
