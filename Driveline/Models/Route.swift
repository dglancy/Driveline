//
//  Route.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class Route {

  // MARK: - Types

  enum RouteStatus: String, Codable {
    case recording
    case finished
  }

  enum RecordingTrigger: String, Codable {
    case automatic = "automatically"
    case manual = "manually"

    // MARK: - Computed properties

    var displayName: String {
      switch self {
      case .automatic:
        String(localized: "Automatically", comment: "Recording trigger: started automatically by automation")
      case .manual:
        String(localized: "Manually", comment: "Recording trigger: started manually by the user")
      }
    }
  }

  // MARK: - Properties

  @Attribute(.unique) var id: UUID
  var name: String
  var startedAt: Date
  var endedAt: Date?

  var startPlaceName: String?
  var endPlaceName: String?

  var trigger: RecordingTrigger
  var status: RouteStatus

  @Relationship(deleteRule: .cascade, inverse: \Position.route)
  var positions: [Position]

  // MARK: - Computed Properties

  var isRecording: Bool { status != .finished }

  var orderedPositions: [Position] {
    return positions
      .sorted(by: { $0.timestamp < $1.timestamp})
  }

  var positionLocationCoordinatesIn2D: [CLLocationCoordinate2D] {
    orderedPositions.map(\.location.coordinate)
  }

  var distanceMetres: Double {
    let sorted = positions.sorted { $0.timestamp < $1.timestamp }
    return zip(sorted, sorted.dropFirst()).reduce(0.0) { total, pair in
      let from = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
      let to = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
      return total + from.distance(from: to)
    }
  }

  var activeDurationSeconds: Double {
    max(0, (endedAt ?? .now).timeIntervalSince(startedAt))
  }

  var avgSpeedMetresPerSecond: CLLocationSpeed {
    guard activeDurationSeconds > 0 else { return 0 }
    return distanceMetres / activeDurationSeconds
  }

  var maxSpeedMetresPerSecond: CLLocationSpeed {
    positions.compactMap { $0.speed >= 0 ? $0.speed : nil }.max() ?? 0
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
    self.status = .recording
    self.positions = []
  }
}
