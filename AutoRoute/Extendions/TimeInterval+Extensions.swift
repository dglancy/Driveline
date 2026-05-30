//
//  TimeInterval+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

public extension TimeInterval {
  func localizedHoursMinutesString(locale: Locale = .current) -> String {
    let formatter = DateComponentsFormatter()
    if self < 3600 {
      formatter.allowedUnits = [.minute]
    } else {
      formatter.allowedUnits = [.hour, .minute]
    }
    formatter.unitsStyle = .abbreviated
    formatter.zeroFormattingBehavior = .pad
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.calendar?.locale = locale

    return formatter.string(from: self) ?? kBlankString
  }

  func localizedDurationString(locale: Locale = .current) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = self >= 3600 ? [.hour, .minute] : [.minute, .second]
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.calendar?.locale = locale
    return formatter.string(from: self) ?? kBlankString
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
