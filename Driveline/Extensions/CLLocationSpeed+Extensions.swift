//
//  CLLocationSpeed+Extensions.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

@MainActor
private enum SpeedFormatterCache {
  static var localeIdentifier: String = ""
  static var measurement: MeasurementFormatter?
  static var number: NumberFormatter?
}

extension Measurement where UnitType == UnitSpeed {

  // MARK: - Private

  private static func preferredUnit(for locale: Locale) -> UnitSpeed {
    locale.measurementSystem == .metric ? .kilometersPerHour : .milesPerHour
  }

  @MainActor
  private static func measurementFormatter(for locale: Locale) -> MeasurementFormatter {
    if SpeedFormatterCache.localeIdentifier == locale.identifier,
       let cached = SpeedFormatterCache.measurement { return cached }
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 0
    if SpeedFormatterCache.localeIdentifier != locale.identifier {
      SpeedFormatterCache.localeIdentifier = locale.identifier
      SpeedFormatterCache.number = nil
    }
    SpeedFormatterCache.measurement = formatter
    return formatter
  }

  @MainActor
  private static func numberFormatter(for locale: Locale) -> NumberFormatter {
    if SpeedFormatterCache.localeIdentifier == locale.identifier,
       let cached = SpeedFormatterCache.number { return cached }
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.maximumFractionDigits = 0
    if SpeedFormatterCache.localeIdentifier != locale.identifier {
      SpeedFormatterCache.localeIdentifier = locale.identifier
      SpeedFormatterCache.measurement = nil
    }
    SpeedFormatterCache.number = formatter
    return formatter
  }

  // MARK: - Methods

  @MainActor
  func localizedSpeedString(locale: Locale = .current) -> String {
    guard self.value >= 0 else { return "" }
    let converted = self.converted(to: Self.preferredUnit(for: locale))
    return Self.measurementFormatter(for: locale).string(from: converted)
  }

  @MainActor
  func localizedSpeedValueString(locale: Locale = .current) -> String {
    guard self.value >= 0 else { return "" }
    let value = self.converted(to: Self.preferredUnit(for: locale)).value
    return Self.numberFormatter(for: locale).string(from: NSNumber(value: value)) ?? ""
  }

  func localizedSpeedUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredUnit(for: locale).symbol
  }
}
