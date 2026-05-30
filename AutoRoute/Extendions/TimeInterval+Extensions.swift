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
}
