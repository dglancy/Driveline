//
//  DriveStats.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

@MainActor
struct DriveStats {

  // MARK: - Properties

  let driveCount: Int
  let totalDistanceMetres: Double

  // MARK: - Lifecycle

  init(drives: [Drive]) {
    driveCount = drives.count
    totalDistanceMetres = drives.reduce(0.0) { $0 + $1.displayDistanceMetres }
  }

  // MARK: - Convenience

  static func recent(from drives: [Drive]) -> DriveStats {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    return DriveStats(drives: drives.filter { $0.startedAt >= cutoff })
  }

  static func allTime(from drives: [Drive]) -> DriveStats {
    DriveStats(drives: drives)
  }
}
