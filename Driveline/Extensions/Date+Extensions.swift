//
//  Date+Extensions.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation

extension Date {
  func clockString(locale: Locale = .current) -> String {
    formatted(.dateTime.hour().minute().locale(locale))
  }

  func longDateString(locale: Locale = .current) -> String {
    formatted(.dateTime.weekday(.wide).month(.wide).day().locale(locale))
  }

  func weekdayName(locale: Locale = .current) -> String {
    formatted(.dateTime.weekday(.wide).locale(locale))
  }

  func monthAndYear(locale: Locale = .current) -> String {
    formatted(.dateTime.month(.wide).year().locale(locale))
  }

  func abbreviatedMonthAndDay(locale: Locale = .current) -> String {
    formatted(.dateTime.month(.abbreviated).day().locale(locale))
  }
}
