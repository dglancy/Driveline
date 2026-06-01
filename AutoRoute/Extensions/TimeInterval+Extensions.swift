//
//  TimeInterval+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

extension TimeInterval {

  // MARK: - Actions

  @MainActor
  func localizedHoursMinutesString(locale: Locale = .current) -> String {
    Self.hoursMinutesFormatter(locale: locale, overHour: self >= 3600).string(from: self) ?? kBlankString
  }

  @MainActor
  func localizedDurationString(locale: Locale = .current) -> String {
    Self.durationFormatter(locale: locale, overHour: self >= 3600).string(from: self) ?? kBlankString
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

  @MainActor private static var hoursMinutesFormatters: [String: DateComponentsFormatter] = [:]
  @MainActor private static var durationFormatters: [String: DateComponentsFormatter] = [:]
  @MainActor private static var elapsedTimeNumberFormatters: [String: NumberFormatter] = [:]

  @MainActor
  private static func hoursMinutesFormatter(locale: Locale, overHour: Bool) -> DateComponentsFormatter {
    let key = "\(locale.identifier)-\(overHour)"
    if let cached = hoursMinutesFormatters[key] { return cached }
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = overHour ? [.hour, .minute] : [.minute]
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.calendar?.locale = locale
    hoursMinutesFormatters[key] = formatter
    return formatter
  }

  @MainActor
  private static func durationFormatter(locale: Locale, overHour: Bool) -> DateComponentsFormatter {
    let key = "\(locale.identifier)-\(overHour)"
    if let cached = durationFormatters[key] { return cached }
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = overHour ? [.hour, .minute] : [.minute, .second]
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.calendar?.locale = locale
    durationFormatters[key] = formatter
    return formatter
  }

  @MainActor
  private static func elapsedTimeNumberFormatter(locale: Locale, padded: Bool) -> NumberFormatter {
    let key = "\(locale.identifier)-\(padded)"
    if let cached = elapsedTimeNumberFormatters[key] { return cached }
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.minimumIntegerDigits = padded ? 2 : 1
    formatter.maximumFractionDigits = 0
    elapsedTimeNumberFormatters[key] = formatter
    return formatter
  }
}
