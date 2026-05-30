//
//  CLLocationSpeed+LocalizedSpeedTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import Foundation
import Testing

@testable import AutoRoute

@Suite
struct CLLocationSpeedLocalizedSpeedTests {

  // MARK: - Unit Symbol

  @Test("metric locale returns km/h symbol")
  func testMetricLocaleUnitSymbol() {
    let locale = Locale(identifier: "fr_FR")
    let speed: CLLocationSpeed = 13.889
    #expect(speed.localizedSpeedUnitSymbol(locale: locale) == "km/h")
  }

  @Test("US locale returns mph symbol")
  func testUSLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_US")
    let speed: CLLocationSpeed = 13.889
    #expect(speed.localizedSpeedUnitSymbol(locale: locale) == "mph")
  }

  @Test("UK locale returns mph symbol")
  func testUKLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_GB")
    let speed: CLLocationSpeed = 13.889
    #expect(speed.localizedSpeedUnitSymbol(locale: locale) == "mph")
  }

  @Test("German locale returns km/h symbol")
  func testGermanLocaleUnitSymbol() {
    let locale = Locale(identifier: "de_DE")
    let speed: CLLocationSpeed = 13.889
    #expect(speed.localizedSpeedUnitSymbol(locale: locale) == "km/h")
  }

  // MARK: - Value String

  @Test("50 km/h in m/s formats as 50 for metric locale")
  func testMetricLocaleValueString() {
    let locale = Locale(identifier: "fr_FR")
    let speed: CLLocationSpeed = 50.0 / 3.6
    #expect(speed.localizedSpeedValueString(locale: locale) == "50")
  }

  @Test("50 km/h in m/s formats as 31 for US locale")
  func testUSLocaleValueString() {
    let locale = Locale(identifier: "en_US")
    let speed: CLLocationSpeed = 50.0 / 3.6
    #expect(speed.localizedSpeedValueString(locale: locale) == "31")
  }

  @Test("50 km/h in m/s formats as 31 for UK locale")
  func testUKLocaleValueString() {
    let locale = Locale(identifier: "en_GB")
    let speed: CLLocationSpeed = 50.0 / 3.6
    #expect(speed.localizedSpeedValueString(locale: locale) == "31")
  }

  @Test("zero speed returns 0 for metric locale")
  func testZeroSpeedMetric() {
    let locale = Locale(identifier: "fr_FR")
    let speed: CLLocationSpeed = 0
    #expect(speed.localizedSpeedValueString(locale: locale) == "0")
  }

  @Test("zero speed returns 0 for US locale")
  func testZeroSpeedUS() {
    let locale = Locale(identifier: "en_US")
    let speed: CLLocationSpeed = 0
    #expect(speed.localizedSpeedValueString(locale: locale) == "0")
  }

  // MARK: - Full String
  // Note: MeasurementFormatter uses locale-specific spacing (e.g. narrow no-break space in fr_FR).
  // Full string tests use en_ locales which produce standard ASCII spaces.

  @Test("50 km/h formats as '50 km/h' for Australian locale")
  func testMetricLocaleFullString() {
    let locale = Locale(identifier: "en_AU")
    let speed: CLLocationSpeed = 50.0 / 3.6
    #expect(speed.localizedSpeedString(locale: locale) == "50 km/h")
  }

  @Test("50 km/h formats as '31 mph' for US locale")
  func testUSLocaleFullString() {
    let locale = Locale(identifier: "en_US")
    let speed: CLLocationSpeed = 50.0 / 3.6
    #expect(speed.localizedSpeedString(locale: locale) == "31 mph")
  }

  @Test("50 km/h formats as '31 mph' for UK locale")
  func testUKLocaleFullString() {
    let locale = Locale(identifier: "en_GB")
    let speed: CLLocationSpeed = 50.0 / 3.6
    #expect(speed.localizedSpeedString(locale: locale) == "31 mph")
  }

  // MARK: - Invalid Speed

  @Test("negative speed returns empty string")
  func testNegativeSpeedReturnsEmpty() {
    let locale = Locale(identifier: "en_GB")
    let speed: CLLocationSpeed = -1
    #expect(speed.localizedSpeedString(locale: locale) == "")
    #expect(speed.localizedSpeedValueString(locale: locale) == "")
  }
}
