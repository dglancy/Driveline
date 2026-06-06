//
//  TimeInterval+Extensions.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

extension TimeInterval {

  // MARK: - Actions

  @MainActor
  func localizedHoursMinutesString(locale: Locale = .current) -> String {
    Self.hoursMinutesFormatter(locale: locale, overHour: self >= 3600).string(from: self) ?? ""
  }

  @MainActor
  func elapsedTimeString(locale: Locale = .current) -> String {
    let padded = Self.elapsedTimeNumberFormatter(locale: locale, padded: true)
    let unpadded = Self.elapsedTimeNumberFormatter(locale: locale, padded: false)
    let total = Int(self)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    let mm = padded.string(from: NSNumber(value: minutes)) ?? String(format: "%02d", minutes)
    let ss = padded.string(from: NSNumber(value: seconds)) ?? String(format: "%02d", seconds)
    guard hours > 0 else { return "\(mm):\(ss)" }
    let hh = unpadded.string(from: NSNumber(value: hours)) ?? "\(hours)"
    return "\(hh):\(mm):\(ss)"
  }

  // MARK: - Private

  @MainActor private static var cachedLocale: String = ""
  @MainActor private static var hoursMinutesFormatterOverHour: DateComponentsFormatter?
  @MainActor private static var hoursMinutesFormatterUnderHour: DateComponentsFormatter?
  @MainActor private static var elapsedNumberFormatterPadded: NumberFormatter?
  @MainActor private static var elapsedNumberFormatterUnpadded: NumberFormatter?

  @MainActor
  private static func invalidateCacheIfNeeded(for locale: Locale) {
    guard cachedLocale != locale.identifier else { return }
    cachedLocale = locale.identifier
    hoursMinutesFormatterOverHour = nil
    hoursMinutesFormatterUnderHour = nil
    elapsedNumberFormatterPadded = nil
    elapsedNumberFormatterUnpadded = nil
  }

  @MainActor
  private static func hoursMinutesFormatter(locale: Locale, overHour: Bool) -> DateComponentsFormatter {
    invalidateCacheIfNeeded(for: locale)
    if overHour, let cached = hoursMinutesFormatterOverHour { return cached }
    if !overHour, let cached = hoursMinutesFormatterUnderHour { return cached }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = overHour ? [.hour, .minute] : [.minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.calendar?.locale = locale
    if overHour { hoursMinutesFormatterOverHour = formatter } else { hoursMinutesFormatterUnderHour = formatter }
    return formatter
  }

  @MainActor
  private static func elapsedTimeNumberFormatter(locale: Locale, padded: Bool) -> NumberFormatter {
    invalidateCacheIfNeeded(for: locale)
    if padded, let cached = elapsedNumberFormatterPadded { return cached }
    if !padded, let cached = elapsedNumberFormatterUnpadded { return cached }
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.minimumIntegerDigits = padded ? 2 : 1
    formatter.maximumFractionDigits = 0
    if padded { elapsedNumberFormatterPadded = formatter } else { elapsedNumberFormatterUnpadded = formatter }
    return formatter
  }
}
