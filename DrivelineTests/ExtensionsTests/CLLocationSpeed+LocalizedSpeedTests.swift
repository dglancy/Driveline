//
//  CLLocationSpeed+LocalizedSpeedTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Testing

@testable import Driveline

@Suite
@MainActor
struct MeasurementLocalizedSpeedTests {

  // MARK: - Unit Symbol

  @Test("metric locale returns km/h symbol")
  func testMetricLocaleUnitSymbol() {
    let locale = Locale(identifier: "fr_FR")
    #expect(Measurement(value: 13.889, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol(locale: locale) == "km/h")
  }

  @Test("US locale returns mph symbol")
  func testUSLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 13.889, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol(locale: locale) == "mph")
  }

  @Test("UK locale returns mph symbol")
  func testUKLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: 13.889, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol(locale: locale) == "mph")
  }

  @Test("German locale returns km/h symbol")
  func testGermanLocaleUnitSymbol() {
    let locale = Locale(identifier: "de_DE")
    #expect(Measurement(value: 13.889, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol(locale: locale) == "km/h")
  }

  // MARK: - Value String

  @Test("50 km/h in m/s formats as 50 for metric locale")
  func testMetricLocaleValueString() {
    let locale = Locale(identifier: "fr_FR")
    #expect(Measurement(value: 50.0 / 3.6, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString(locale: locale) == "50")
  }

  @Test("50 km/h in m/s formats as 31 for US locale")
  func testUSLocaleValueString() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 50.0 / 3.6, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString(locale: locale) == "31")
  }

  @Test("50 km/h in m/s formats as 31 for UK locale")
  func testUKLocaleValueString() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: 50.0 / 3.6, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString(locale: locale) == "31")
  }

  @Test("zero speed returns 0 for metric locale")
  func testZeroSpeedMetric() {
    let locale = Locale(identifier: "fr_FR")
    #expect(Measurement(value: 0, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString(locale: locale) == "0")
  }

  @Test("zero speed returns 0 for US locale")
  func testZeroSpeedUS() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 0, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString(locale: locale) == "0")
  }

  // MARK: - Full String
  // Note: MeasurementFormatter uses locale-specific spacing (e.g. narrow no-break space in fr_FR).
  // Full string tests use en_ locales which produce standard ASCII spaces.

  @Test("50 km/h formats as '50 km/h' for Australian locale")
  func testMetricLocaleFullString() {
    let locale = Locale(identifier: "en_AU")
    #expect(Measurement(value: 50.0 / 3.6, unit: UnitSpeed.metersPerSecond).localizedSpeedString(locale: locale) == "50 km/h")
  }

  @Test("50 km/h formats as '31 mph' for US locale")
  func testUSLocaleFullString() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 50.0 / 3.6, unit: UnitSpeed.metersPerSecond).localizedSpeedString(locale: locale) == "31 mph")
  }

  @Test("50 km/h formats as '31 mph' for UK locale")
  func testUKLocaleFullString() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: 50.0 / 3.6, unit: UnitSpeed.metersPerSecond).localizedSpeedString(locale: locale) == "31 mph")
  }

  // MARK: - Invalid Speed

  @Test("negative speed returns empty string")
  func testNegativeSpeedReturnsEmpty() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: -1, unit: UnitSpeed.metersPerSecond).localizedSpeedString(locale: locale) == "")
    #expect(Measurement(value: -1, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString(locale: locale) == "")
  }
}
