//
//  Double+LocalizedDistanceTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Testing

@testable import Driveline

@Suite
@MainActor
struct MeasurementLocalizedDistanceTests {

  // MARK: - Unit Symbol

  @Test("metric locale returns km symbol")
  func testMetricLocaleUnitSymbol() {
    let locale = Locale(identifier: "fr_FR")
    #expect(Measurement(value: 1000.0, unit: UnitLength.meters).localizedDistanceUnitSymbol(locale: locale) == "km")
  }

  @Test("US locale returns mi symbol")
  func testUSLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 1000.0, unit: UnitLength.meters).localizedDistanceUnitSymbol(locale: locale) == "mi")
  }

  @Test("UK locale returns mi symbol")
  func testUKLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: 1000.0, unit: UnitLength.meters).localizedDistanceUnitSymbol(locale: locale) == "mi")
  }

  @Test("German locale returns km symbol")
  func testGermanLocaleUnitSymbol() {
    let locale = Locale(identifier: "de_DE")
    #expect(Measurement(value: 1000.0, unit: UnitLength.meters).localizedDistanceUnitSymbol(locale: locale) == "km")
  }

  // MARK: - Value String

  @Test("1000 m formats as 1.0 km for metric locale")
  func testMetricLocaleValueString() {
    let locale = Locale(identifier: "en_AU")
    #expect(Measurement(value: 1000.0, unit: UnitLength.meters).localizedDistanceValueString(locale: locale) == "1.0")
  }

  @Test("1000 m formats as 1,0 km for French locale")
  func testFrenchLocaleValueString() {
    let locale = Locale(identifier: "fr_FR")
    #expect(Measurement(value: 1000.0, unit: UnitLength.meters).localizedDistanceValueString(locale: locale) == "1,0")
  }

  @Test("1609.344 m formats as 1.0 mi for US locale")
  func testUSLocaleValueString() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 1609.344, unit: UnitLength.meters).localizedDistanceValueString(locale: locale) == "1.0")
  }

  @Test("1609.344 m formats as 1.0 mi for UK locale")
  func testUKLocaleValueString() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: 1609.344, unit: UnitLength.meters).localizedDistanceValueString(locale: locale) == "1.0")
  }

  @Test("zero metres formats as 0.0 for metric locale")
  func testZeroDistanceMetric() {
    let locale = Locale(identifier: "fr_FR")
    #expect(Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceValueString(locale: locale) == "0,0")
  }

  @Test("zero metres formats as 0.0 for US locale")
  func testZeroDistanceUS() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceValueString(locale: locale) == "0.0")
  }

  // MARK: - Full String

  @Test("10000 m formats as '10.0 km' for Australian locale")
  func testAustralianLocaleFullString() {
    let locale = Locale(identifier: "en_AU")
    #expect(Measurement(value: 10000.0, unit: UnitLength.meters).localizedDistanceString(locale: locale) == "10.0 km")
  }

  @Test("1609.344 m formats as '1.0 mi' for US locale")
  func testUSLocaleFullString() {
    let locale = Locale(identifier: "en_US")
    #expect(Measurement(value: 1609.344, unit: UnitLength.meters).localizedDistanceString(locale: locale) == "1.0 mi")
  }

  @Test("1609.344 m formats as '1.0 mi' for UK locale")
  func testUKLocaleFullString() {
    let locale = Locale(identifier: "en_GB")
    #expect(Measurement(value: 1609.344, unit: UnitLength.meters).localizedDistanceString(locale: locale) == "1.0 mi")
  }
}
