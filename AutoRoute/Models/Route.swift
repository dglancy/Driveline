//
//  Route.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import SwiftData

@Model
final class Route {
  
  // MARK: - Properties
  
  @Attribute(.unique) var id: UUID
  var name: String
  var startDate: Date
  var endDate: Date?

  var startPlaceName: String?
  var endPlaceName: String?

  var trigger: RecordingTrigger

  var isRecording: Bool
  var isPaused: Bool
  var pausedDurationSeconds: Double
  var pauseStartedAt: Date?

  @Relationship(deleteRule: .cascade, inverse: \TrackPoint.route)
  var trackPoints: [TrackPoint]

  // MARK: - Computed Properties
  
  var durationSeconds: Double {
    let reference = endDate ?? .now
    let currentPause = isPaused ? Date.now.timeIntervalSince(pauseStartedAt ?? .now) : 0
    return max(0, reference.timeIntervalSince(startDate) - pausedDurationSeconds - currentPause)
  }

  // MARK: - Lifecycle
  
  init(name: String, trigger: RecordingTrigger = .manual) {
    self.id = UUID()
    self.name = name
    self.startDate = .now
    self.endDate = nil
    self.startPlaceName = nil
    self.endPlaceName = nil
    self.trigger = trigger
    self.isRecording = true
    self.isPaused = false
    self.pausedDurationSeconds = 0
    self.pauseStartedAt = nil
    self.trackPoints = []
  }
}

enum RecordingTrigger: String, Codable {
  case bluetooth = "Bluetooth"
  case manual = "Started manually"
}
