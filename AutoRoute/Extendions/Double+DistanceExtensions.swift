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

  // MARK: - Methods

  func localizedDistanceString(locale: Locale = .current) -> String {
    let converted = Measurement(value: self, unit: UnitLength.meters)
      .converted(to: Self.preferredDistanceUnit(for: locale))
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 1
    formatter.numberFormatter.minimumFractionDigits = 1
    return formatter.string(from: converted)
  }

  func localizedDistanceValueString(locale: Locale = .current) -> String {
    let value = Measurement(value: self, unit: UnitLength.meters)
      .converted(to: Self.preferredDistanceUnit(for: locale)).value
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.maximumFractionDigits = 1
    formatter.minimumFractionDigits = 1
    return formatter.string(from: NSNumber(value: value)) ?? kBlankString
  }

  func localizedDistanceUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredDistanceUnit(for: locale).symbol
  }
}
