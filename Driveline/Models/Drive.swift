//
//  Drive.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class Drive {

  // MARK: - Types

  enum DriveStatus: String, Codable {
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

  var id: UUID = UUID()
  var name: String?
  var startedAt: Date = Date()
  var endedAt: Date?

  var startPlaceName: String?
  var endPlaceName: String?

  var trigger: RecordingTrigger = RecordingTrigger.manual
  var status: DriveStatus = DriveStatus.recording

  @Relationship(deleteRule: .cascade, inverse: \Position.drive)
  var positions: [Position]?

  var accumulatedDistanceMetres: Double = 0

  // MARK: - Computed Properties

  var displayName: String {
    if let name { return name }
    let timeWord = Self.timeOfDayWord(for: startedAt)
    switch (startPlaceName, endPlaceName) {
    case (let start?, let end?): return "\(start) \u{2192} \(end)"
    case (let start?, nil): return String(localized: "\(timeWord) drive from \(start)", comment: "Drive name with known start location only")
    case (nil, let end?): return String(localized: "\(timeWord) drive to \(end)", comment: "Drive name with known end location only")
    case (nil, nil): return Self.timeOfDayDriveName(for: startedAt)
    }
  }

  var isRecording: Bool { status != .finished }

  var orderedPositions: [Position] {
    guard let positions else { return [] }
    return positions.sorted(by: { $0.timestamp < $1.timestamp })
  }

  var positionLocationCoordinatesIn2D: [CLLocationCoordinate2D] {
    orderedPositions.map(\.location.coordinate)
  }

  var distanceMetres: Double {
    let sorted = orderedPositions
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
    guard let positions else { return 0 }
    let speeds = positions.compactMap { $0.speed >= 0 ? $0.speed : nil }
    return speeds.max() ?? 0
  }

  // MARK: - Lifecycle

  init(name: String? = nil, trigger: RecordingTrigger = .manual) {
    self.id = UUID()
    self.name = name
    self.startedAt = .now
    self.endedAt = nil
    self.startPlaceName = nil
    self.endPlaceName = nil
    self.trigger = trigger
    self.status = .recording
    self.positions = nil
    self.accumulatedDistanceMetres = 0
  }

  // MARK: - Private

  private static func timeOfDayDriveName(for date: Date) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 5..<12: return String(localized: "Morning Drive", comment: "Auto drive name — morning")
    case 12..<17: return String(localized: "Afternoon Drive", comment: "Auto drive name — afternoon")
    case 17..<21: return String(localized: "Evening Drive", comment: "Auto drive name — evening")
    default: return String(localized: "Night Drive", comment: "Auto drive name — night")
    }
  }

  private static func timeOfDayWord(for date: Date) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 5..<12: return String(localized: "Morning", comment: "Time-of-day word in drive name")
    case 12..<17: return String(localized: "Afternoon", comment: "Time-of-day word in drive name")
    case 17..<21: return String(localized: "Evening", comment: "Time-of-day word in drive name")
    default: return String(localized: "Night", comment: "Time-of-day word in drive name")
    }
  }
}
