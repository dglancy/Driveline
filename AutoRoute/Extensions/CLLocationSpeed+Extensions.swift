//
//  CLLocationSpeed+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation

extension CLLocationSpeed {

  // MARK: - Private

  private static func preferredUnit(for locale: Locale) -> UnitSpeed {
    locale.measurementSystem == .metric ? .kilometersPerHour : .milesPerHour
  }

  @MainActor private static var speedMeasurementFormatterCache: [String: MeasurementFormatter] = [:]
  @MainActor private static var speedNumberFormatterCache: [String: NumberFormatter] = [:]

  @MainActor
  private static func speedMeasurementFormatter(for locale: Locale) -> MeasurementFormatter {
    let key = locale.identifier
    if let cached = speedMeasurementFormatterCache[key] { return cached }
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 0
    speedMeasurementFormatterCache[key] = formatter
    return formatter
  }

  @MainActor
  private static func speedNumberFormatter(for locale: Locale) -> NumberFormatter {
    let key = locale.identifier
    if let cached = speedNumberFormatterCache[key] { return cached }
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.maximumFractionDigits = 0
    speedNumberFormatterCache[key] = formatter
    return formatter
  }

  // MARK: - Methods

  @MainActor
  func localizedSpeedString(locale: Locale = .current) -> String {
    guard self >= 0 else { return kBlankString }
    let converted = Measurement(value: self, unit: UnitSpeed.metersPerSecond)
      .converted(to: Self.preferredUnit(for: locale))
    return Self.speedMeasurementFormatter(for: locale).string(from: converted)
  }

  @MainActor
  func localizedSpeedValueString(locale: Locale = .current) -> String {
    guard self >= 0 else { return kBlankString }
    let value = Measurement(value: self, unit: UnitSpeed.metersPerSecond)
      .converted(to: Self.preferredUnit(for: locale)).value
    return Self.speedNumberFormatter(for: locale).string(from: NSNumber(value: value)) ?? kBlankString
  }

  func localizedSpeedUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredUnit(for: locale).symbol
  }
}
