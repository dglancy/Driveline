//
//  TimeInterval+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

extension TimeInterval {

  // MARK: - Private

  @MainActor private static var hoursMinutesSubHourFormatters: [String: DateComponentsFormatter] = [:]
  @MainActor private static var hoursMinutesOverHourFormatters: [String: DateComponentsFormatter] = [:]
  @MainActor private static var durationSubHourFormatters: [String: DateComponentsFormatter] = [:]
  @MainActor private static var durationOverHourFormatters: [String: DateComponentsFormatter] = [:]

  @MainActor
  private static func hoursMinutesFormatter(locale: Locale, overHour: Bool) -> DateComponentsFormatter {
    let key = locale.identifier
    if overHour {
      if let cached = hoursMinutesOverHourFormatters[key] { return cached }
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute]
      formatter.unitsStyle = .abbreviated
      formatter.zeroFormattingBehavior = .pad
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.calendar?.locale = locale
      hoursMinutesOverHourFormatters[key] = formatter
      return formatter
    } else {
      if let cached = hoursMinutesSubHourFormatters[key] { return cached }
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.minute]
      formatter.unitsStyle = .abbreviated
      formatter.zeroFormattingBehavior = .pad
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.calendar?.locale = locale
      hoursMinutesSubHourFormatters[key] = formatter
      return formatter
    }
  }

  @MainActor
  private static func durationFormatter(locale: Locale, overHour: Bool) -> DateComponentsFormatter {
    let key = locale.identifier
    if overHour {
      if let cached = durationOverHourFormatters[key] { return cached }
      let formatter = DateComponentsFormatter()
      formatter.unitsStyle = .abbreviated
      formatter.allowedUnits = [.hour, .minute]
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.calendar?.locale = locale
      durationOverHourFormatters[key] = formatter
      return formatter
    } else {
      if let cached = durationSubHourFormatters[key] { return cached }
      let formatter = DateComponentsFormatter()
      formatter.unitsStyle = .abbreviated
      formatter.allowedUnits = [.minute, .second]
      formatter.calendar = Calendar(identifier: .gregorian)
      formatter.calendar?.locale = locale
      durationSubHourFormatters[key] = formatter
      return formatter
    }
  }

  // MARK: - Methods

  @MainActor
  func localizedHoursMinutesString(locale: Locale = .current) -> String {
    Self.hoursMinutesFormatter(locale: locale, overHour: self >= 3600).string(from: self) ?? kBlankString
  }

  @MainActor
  func localizedDurationString(locale: Locale = .current) -> String {
    Self.durationFormatter(locale: locale, overHour: self >= 3600).string(from: self) ?? kBlankString
  }

  func elapsedTimeString() -> String {
    let total = Int(self)
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
}
