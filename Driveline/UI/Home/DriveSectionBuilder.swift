//
//  DriveSectionBuilder.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

@MainActor
enum DriveSectionBuilder {

  // MARK: - Public

  static func sections(
    from drives: [Drive],
    searchText: String,
    now: Date = .now,
    calendar: Calendar = .current
  ) -> [DriveSection] {
    let filtered = filter(drives, by: searchText)
    return buildSections(from: filtered, now: now, calendar: calendar)
  }

  // MARK: - Private

  private static func filter(_ drives: [Drive], by query: String) -> [Drive] {
    guard !query.isEmpty else { return drives }
    return drives.filter { matches($0, query) }
  }

  private static func matches(_ drive: Drive, _ query: String) -> Bool {
    drive.displayName.localizedCaseInsensitiveContains(query) ||
      drive.startPlaceName?.localizedCaseInsensitiveContains(query) == true ||
      drive.endPlaceName?.localizedCaseInsensitiveContains(query) == true
  }

  private static func buildSections(from drives: [Drive], now: Date, calendar: Calendar) -> [DriveSection] {
    let today = calendar.startOfDay(for: now)
    var groupMap: [String: [DriveRow]] = [:]
    var orderedKeys: [String] = []

    for drive in drives.sorted(by: { $0.startedAt > $1.startedAt }) {
      let key = sectionTitle(for: drive.startedAt, today: today, calendar: calendar)
      let row = DriveRow(drive: drive)
      if groupMap[key] == nil { orderedKeys.append(key) }
      groupMap[key, default: []].append(row)
    }

    return orderedKeys.map { DriveSection(title: $0, rows: groupMap[$0] ?? []) }
  }

  static func sectionTitle(for date: Date, today: Date, calendar: Calendar) -> String {
    let driveDay = calendar.startOfDay(for: date)
    let daysDiff = calendar.dateComponents([.day], from: driveDay, to: today).day ?? 0
    switch daysDiff {
    case 0: return String(localized: "Today")
    case 1: return String(localized: "Yesterday")
    case 2...6: return date.weekdayName()
    default: return date.monthAndYear()
    }
  }
}
