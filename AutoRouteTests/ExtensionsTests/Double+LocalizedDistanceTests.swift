//
//  Double+LocalizedDistanceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Testing

@testable import AutoRoute

@Suite
struct DoubleLocalizedDistanceTests {

  // MARK: - Unit Symbol

  @Test("metric locale returns km symbol")
  func testMetricLocaleUnitSymbol() {
    let locale = Locale(identifier: "fr_FR")
    #expect(1000.0.localizedDistanceUnitSymbol(locale: locale) == "km")
  }

  @Test("US locale returns mi symbol")
  func testUSLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_US")
    #expect(1000.0.localizedDistanceUnitSymbol(locale: locale) == "mi")
  }

  @Test("UK locale returns mi symbol")
  func testUKLocaleUnitSymbol() {
    let locale = Locale(identifier: "en_GB")
    #expect(1000.0.localizedDistanceUnitSymbol(locale: locale) == "mi")
  }

  @Test("German locale returns km symbol")
  func testGermanLocaleUnitSymbol() {
    let locale = Locale(identifier: "de_DE")
    #expect(1000.0.localizedDistanceUnitSymbol(locale: locale) == "km")
  }

  // MARK: - Value String

  @Test("1000 m formats as 1.0 km for metric locale")
  func testMetricLocaleValueString() {
    let locale = Locale(identifier: "en_AU")
    #expect(1000.0.localizedDistanceValueString(locale: locale) == "1.0")
  }

  @Test("1000 m formats as 1,0 km for French locale")
  func testFrenchLocaleValueString() {
    let locale = Locale(identifier: "fr_FR")
    #expect(1000.0.localizedDistanceValueString(locale: locale) == "1,0")
  }

  @Test("1609.344 m formats as 1.0 mi for US locale")
  func testUSLocaleValueString() {
    let locale = Locale(identifier: "en_US")
    #expect(1609.344.localizedDistanceValueString(locale: locale) == "1.0")
  }

  @Test("1609.344 m formats as 1.0 mi for UK locale")
  func testUKLocaleValueString() {
    let locale = Locale(identifier: "en_GB")
    #expect(1609.344.localizedDistanceValueString(locale: locale) == "1.0")
  }

  @Test("zero metres formats as 0.0 for metric locale")
  func testZeroDistanceMetric() {
    let locale = Locale(identifier: "fr_FR")
    #expect(0.0.localizedDistanceValueString(locale: locale) == "0,0")
  }

  @Test("zero metres formats as 0.0 for US locale")
  func testZeroDistanceUS() {
    let locale = Locale(identifier: "en_US")
    #expect(0.0.localizedDistanceValueString(locale: locale) == "0.0")
  }

  // MARK: - Full String

  @Test("10000 m formats as '10.0 km' for Australian locale")
  func testAustralianLocaleFullString() {
    let locale = Locale(identifier: "en_AU")
    #expect(10000.0.localizedDistanceString(locale: locale) == "10.0 km")
  }

  @Test("1609.344 m formats as '1.0 mi' for US locale")
  func testUSLocaleFullString() {
    let locale = Locale(identifier: "en_US")
    #expect(1609.344.localizedDistanceString(locale: locale) == "1.0 mi")
  }

  @Test("1609.344 m formats as '1.0 mi' for UK locale")
  func testUKLocaleFullString() {
    let locale = Locale(identifier: "en_GB")
    #expect(1609.344.localizedDistanceString(locale: locale) == "1.0 mi")
  }
}
