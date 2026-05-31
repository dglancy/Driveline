//
//  Double+DistanceExtensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

extension Double {

  // MARK: - Private

  private static func preferredDistanceUnit(for locale: Locale) -> UnitLength {
    locale.measurementSystem == .metric ? .kilometers : .miles
  }

  @MainActor private static var distanceMeasurementFormatterCache: [String: MeasurementFormatter] = [:]
  @MainActor private static var distanceNumberFormatterCache: [String: NumberFormatter] = [:]

  @MainActor
  private static func distanceMeasurementFormatter(for locale: Locale) -> MeasurementFormatter {
    let key = locale.identifier
    if let cached = distanceMeasurementFormatterCache[key] { return cached }
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 1
    formatter.numberFormatter.minimumFractionDigits = 1
    distanceMeasurementFormatterCache[key] = formatter
    return formatter
  }

  @MainActor
  private static func distanceNumberFormatter(for locale: Locale) -> NumberFormatter {
    let key = locale.identifier
    if let cached = distanceNumberFormatterCache[key] { return cached }
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 1
    distanceNumberFormatterCache[key] = formatter
    return formatter
  }

  // MARK: - Methods

  @MainActor
  func localizedDistanceString(locale: Locale = .current) -> String {
    let converted = Measurement(value: self, unit: UnitLength.meters)
      .converted(to: Self.preferredDistanceUnit(for: locale))
    return Self.distanceMeasurementFormatter(for: locale).string(from: converted)
  }

  @MainActor
  func localizedDistanceValueString(locale: Locale = .current) -> String {
    let value = Measurement(value: self, unit: UnitLength.meters)
      .converted(to: Self.preferredDistanceUnit(for: locale)).value
    return Self.distanceNumberFormatter(for: locale).string(from: NSNumber(value: value)) ?? kBlankString
  }

  func localizedDistanceUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredDistanceUnit(for: locale).symbol
  }
}
