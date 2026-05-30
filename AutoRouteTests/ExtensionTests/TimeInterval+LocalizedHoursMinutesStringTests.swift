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
struct TimeIntervalLocalizedHoursMinutesStringTests {
  
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
}
