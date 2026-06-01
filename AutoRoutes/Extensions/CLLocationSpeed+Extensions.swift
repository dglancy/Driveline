//
//  CLLocationSpeed+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

@MainActor
private enum SpeedFormatterCache {
  static var measurements: [String: MeasurementFormatter] = [:]
  static var numbers: [String: NumberFormatter] = [:]
}

extension Measurement where UnitType == UnitSpeed {

  // MARK: - Private

  private static func preferredUnit(for locale: Locale) -> UnitSpeed {
    locale.measurementSystem == .metric ? .kilometersPerHour : .milesPerHour
  }

  @MainActor
  private static func measurementFormatter(for locale: Locale) -> MeasurementFormatter {
    let key = locale.identifier
    if let cached = SpeedFormatterCache.measurements[key] { return cached }
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 0
    SpeedFormatterCache.measurements[key] = formatter
    return formatter
  }

  @MainActor
  private static func numberFormatter(for locale: Locale) -> NumberFormatter {
    let key = locale.identifier
    if let cached = SpeedFormatterCache.numbers[key] { return cached }
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.maximumFractionDigits = 0
    SpeedFormatterCache.numbers[key] = formatter
    return formatter
  }

  // MARK: - Methods

  @MainActor
  func localizedSpeedString(locale: Locale = .current) -> String {
    guard self.value >= 0 else { return kBlankString }
    let converted = self.converted(to: Self.preferredUnit(for: locale))
    return Self.measurementFormatter(for: locale).string(from: converted)
  }

  @MainActor
  func localizedSpeedValueString(locale: Locale = .current) -> String {
    guard self.value >= 0 else { return kBlankString }
    let value = self.converted(to: Self.preferredUnit(for: locale)).value
    return Self.numberFormatter(for: locale).string(from: NSNumber(value: value)) ?? kBlankString
  }

  func localizedSpeedUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredUnit(for: locale).symbol
  }
}
