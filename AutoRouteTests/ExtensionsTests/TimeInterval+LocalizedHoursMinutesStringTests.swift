//
//  TimeInterval+LocalizedHoursMinutesStringTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

@testable import AutoRoute
import Testing
import Foundation

@Suite
@MainActor
struct TimeIntervalTests {
  
  @Test("zero seconds returns 0m for en_GB locale")
  func testZeroSecondsReturns0m() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 0
    #expect(ti.localizedHoursMinutesString(locale: locale) == "0m")
  }
  
  @Test("under one hour uses minutes only: 59 minutes returns 59m in en_GB")
  func testUnderOneHourUsesMinutesOnly() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 59 * 60
    #expect(ti.localizedHoursMinutesString(locale: locale) == "59m")
  }
  
  @Test("exactly one hour returns 1h 00m in en_GB")
  func testExactlyOneHour() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 3600
    #expect(ti.localizedHoursMinutesString(locale: locale) == "1h 0m")
  }
  
  @Test("hours and minutes: 1 hour 5 minutes returns 1h 05m in en_GB")
  func testHoursAndMinutes() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 3600 + 5 * 60
    #expect(ti.localizedHoursMinutesString(locale: locale) == "1h 5m")
  }
  
  @Test("multiple hours: 2 hours 30 minutes returns 2h 30m in en_GB")
  func testMultipleHours() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 2 * 3600 + 30 * 60
    #expect(ti.localizedHoursMinutesString(locale: locale) == "2h 30m")
  }
  
  @Test("different locale fr_FR: 59 minutes returns 59 min")
  func testDifferentLocaleMinutesOnly() {
    let locale = Locale(identifier: "fr_FR")
    let ti: TimeInterval = 59 * 60
    #expect(ti.localizedHoursMinutesString(locale: locale) == "59min")
  }
  
  @Test("different locale fr_FR: exactly 1 hour returns 1 h 00 min")
  func testDifferentLocaleExactlyOneHour() {
    let locale = Locale(identifier: "fr_FR")
    let ti: TimeInterval = 3600
    #expect(ti.localizedHoursMinutesString(locale: locale) == "1h 0min")
  }
  
  @Test("large value: 10 hours exactly returns 10h 00m in en_GB")
  func testLargeValueTenHours() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 10 * 3600
    #expect(ti.localizedHoursMinutesString(locale: locale) == "10h 0m")
  }

  // MARK: - localizedDurationString

  @Test("30 seconds returns '30s' in en_GB")
  func testDuration30Seconds() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(30).localizedDurationString(locale: locale) == "30s")
  }

  @Test("90 seconds returns '1m 30s' in en_GB")
  func testDuration90Seconds() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(90).localizedDurationString(locale: locale) == "1m 30s")
  }

  @Test("59 minutes and 59 seconds returns abbreviated with seconds in en_GB")
  func testDurationUnderOneHour() {
    let locale = Locale(identifier: "en_GB")
    let ti: TimeInterval = 59 * 60 + 59
    #expect(ti.localizedDurationString(locale: locale) == "59m 59s")
  }

  @Test("exactly 1 hour returns '1h' in en_GB (trailing zero dropped without padding)")
  func testDurationExactlyOneHour() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(3600).localizedDurationString(locale: locale) == "1h")
  }

  @Test("1 hour 30 minutes returns '1h 30m' in en_GB")
  func testDurationOneHourThirtyMinutes() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(5400).localizedDurationString(locale: locale) == "1h 30m")
  }

  @Test("90 seconds returns '1min 30s' in fr_FR")
  func testDurationFrenchLocale() {
    let locale = Locale(identifier: "fr_FR")
    #expect(TimeInterval(90).localizedDurationString(locale: locale) == "1min 30s")
  }

  @Test("1 hour 30 minutes returns '1h 30min' in fr_FR")
  func testDurationFrenchLocaleOverOneHour() {
    let locale = Locale(identifier: "fr_FR")
    #expect(TimeInterval(5400).localizedDurationString(locale: locale) == "1h 30min")
  }

  // MARK: - elapsedTimeString

  @Test("0 seconds returns '00:00' in en_GB")
  func testElapsedZeroSeconds() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(0).elapsedTimeString(locale: locale) == "00:00")
  }

  @Test("65 seconds returns '01:05' in en_GB")
  func testElapsed65Seconds() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(65).elapsedTimeString(locale: locale) == "01:05")
  }

  @Test("59 minutes 59 seconds returns '59:59' in en_GB")
  func testElapsed59MinutesWith59Seconds() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(59 * 60 + 59).elapsedTimeString(locale: locale) == "59:59")
  }

  @Test("exactly 1 hour returns '1:00:00' in en_GB")
  func testElapsedExactlyOneHour() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(3600).elapsedTimeString(locale: locale) == "1:00:00")
  }

  @Test("1 hour 1 minute 1 second returns '1:01:01' in en_GB")
  func testElapsedOneHourOneMinuteOneSecond() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(3661).elapsedTimeString(locale: locale) == "1:01:01")
  }

  @Test("10 hours returns '10:00:00' in en_GB")
  func testElapsedTenHours() {
    let locale = Locale(identifier: "en_GB")
    #expect(TimeInterval(36000).elapsedTimeString(locale: locale) == "10:00:00")
  }

  @Test("ar_EG locale uses Arabic-Indic digits")
  func testElapsedArabicLocaleUsesLocalisedDigits() {
    let locale = Locale(identifier: "ar_EG")
    let result = TimeInterval(65).elapsedTimeString(locale: locale)
    #expect(result == "٠١:٠٥")
  }
}
