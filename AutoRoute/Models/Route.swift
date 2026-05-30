//
//  Route.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class Route {

  // MARK: - Properties

  @Attribute(.unique) var id: UUID
  var name: String
  var startedAt: Date
  var endedAt: Date?

  var startPlaceName: String?
  var endPlaceName: String?

  var trigger: RecordingTrigger

  var isRecording: Bool
  var isPaused: Bool
  var pausedDurationSeconds: Double
  var pauseStartedAt: Date?

  @Relationship(deleteRule: .cascade, inverse: \Position.route)
  var positions: [Position]

  // MARK: - Computed Properties

  var distanceMetres: Double {
    let sorted = positions.sorted { $0.timestamp < $1.timestamp }
    guard sorted.count > 1 else { return 0 }
    var total = 0.0
    for i in 1..<sorted.count {
      let from = CLLocation(latitude: sorted[i - 1].latitude, longitude: sorted[i - 1].longitude)
      let to = CLLocation(latitude: sorted[i].latitude, longitude: sorted[i].longitude)
      total += from.distance(from: to)
    }
    return total
  }

  var distanceKilometres: Double { distanceMetres / 1_000 }

  var durationSeconds: Double {
    let reference = endedAt ?? .now
    let currentPause = isPaused ? Date.now.timeIntervalSince(pauseStartedAt ?? .now) : 0
    return max(0, reference.timeIntervalSince(startedAt) - pausedDurationSeconds - currentPause)
  }

  // MARK: - Lifecycle

  init(name: String, trigger: RecordingTrigger = .manual) {
    self.id = UUID()
    self.name = name
    self.startedAt = .now
    self.endedAt = nil
    self.startPlaceName = nil
    self.endPlaceName = nil
    self.trigger = trigger
    self.isRecording = true
    self.isPaused = false
    self.pausedDurationSeconds = 0
    self.pauseStartedAt = nil
    self.positions = []
  }
}

enum RecordingTrigger: String, Codable {
  case bluetooth = "Bluetooth"
  case manual = "Started manually"
}
