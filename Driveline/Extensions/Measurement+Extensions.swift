//
//  Measurement+Extensions.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

@MainActor
private enum DistanceFormatterCache {
  static var localeIdentifier: String = ""
  static var measurement: MeasurementFormatter?
  static var number: NumberFormatter?
}

extension Measurement where UnitType == UnitLength {

  // MARK: - Static methods
  
  static func localizedDistanceUnitSymbol(locale: Locale = .current) -> String {
    preferredUnit(for: locale).symbol
  }
  
  // MARK: - Methods

  @MainActor
  func localizedDistanceString(locale: Locale = .current) -> String {
    let converted = self.converted(to: Self.preferredUnit(for: locale))
    return Self.measurementFormatter(for: locale).string(from: converted)
  }

  @MainActor
  func localizedDistanceValueString(locale: Locale = .current) -> String {
    let value = self.converted(to: Self.preferredUnit(for: locale)).value
    let fractionDigits = value > 100 ? 0 : 1
    return Self.numberFormatter(for: locale, fractionDigits: fractionDigits).string(from: NSNumber(value: value)) ?? ""
  }

  func localizedDistanceUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredUnit(for: locale).symbol
  }
  
  // MARK: - Private

  private static func preferredUnit(for locale: Locale) -> UnitLength {
    locale.measurementSystem == .metric ? .kilometers : .miles
  }

  @MainActor
  private static func measurementFormatter(for locale: Locale) -> MeasurementFormatter {
    if DistanceFormatterCache.localeIdentifier == locale.identifier,
       let cached = DistanceFormatterCache.measurement { return cached }
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 1
    formatter.numberFormatter.minimumFractionDigits = 1
    if DistanceFormatterCache.localeIdentifier != locale.identifier {
      DistanceFormatterCache.localeIdentifier = locale.identifier
      DistanceFormatterCache.number = nil
    }
    DistanceFormatterCache.measurement = formatter
    return formatter
  }

  @MainActor
  private static func numberFormatter(for locale: Locale, fractionDigits: Int) -> NumberFormatter {
    let formatter: NumberFormatter
    if DistanceFormatterCache.localeIdentifier == locale.identifier,
       let cached = DistanceFormatterCache.number {
      formatter = cached
    } else {
      formatter = NumberFormatter()
      formatter.locale = locale
      DistanceFormatterCache.localeIdentifier = locale.identifier
      DistanceFormatterCache.measurement = nil
      DistanceFormatterCache.number = formatter
    }
    formatter.maximumFractionDigits = fractionDigits
    formatter.minimumFractionDigits = fractionDigits
    return formatter
  }
}
