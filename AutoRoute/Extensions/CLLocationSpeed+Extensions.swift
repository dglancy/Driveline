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

  // MARK: - Methods

  func localizedSpeedString(locale: Locale = .current) -> String {
    guard self >= 0 else { return kBlankString }
    let converted = Measurement(value: self, unit: UnitSpeed.metersPerSecond)
      .converted(to: Self.preferredUnit(for: locale))
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 0
    return formatter.string(from: converted)
  }

  func localizedSpeedValueString(locale: Locale = .current) -> String {
    guard self >= 0 else { return kBlankString }
    let value = Measurement(value: self, unit: UnitSpeed.metersPerSecond)
      .converted(to: Self.preferredUnit(for: locale)).value
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? kBlankString
  }

  func localizedSpeedUnitSymbol(locale: Locale = .current) -> String {
    Self.preferredUnit(for: locale).symbol
  }
}
