//
//  DriveActivityAttributes.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

#if os(iOS)
import ActivityKit
import Foundation

nonisolated struct DriveActivityAttributes: ActivityAttributes {

  // MARK: - Properties

  let startedAt: Date

  // MARK: - Content State

  struct ContentState: Codable, Hashable {
    // MARK: - Properties

    let startPlaceName: String?
    let distanceMetres: Double
    let avgSpeedMetresPerSecond: Double
  }
}
#endif
