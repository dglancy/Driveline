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

  enum Category: String, Codable {
    case none
    case errand
    case urban
    case roadTrip
    case scenic
    case mixed

    // MARK: - Computed properties

    var displayName: String {
      switch self {
      case .none:
        String(localized: "None", comment: "Drive category: not categorized")
      case .errand:
        String(localized: "Errand", comment: "Drive category: short, practical drive")
      case .urban:
        String(localized: "Urban", comment: "Drive category: city or town driving")
      case .roadTrip:
        String(localized: "Road Trip", comment: "Drive category: long-distance journey")
      case .scenic:
        String(localized: "Scenic", comment: "Drive category: scenic or leisure drive")
      case .mixed:
        String(localized: "Mixed", comment: "Drive category: a mix of driving types")
      }
    }

    // MARK: - Parsing

    static func from(string: String) -> Category {
      switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
      case "errand": .errand
      case "urban": .urban
      case "road trip": .roadTrip
      case "scenic": .scenic
      case "mixed": .mixed
      default: .none
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

  @Relationship(deleteRule: .cascade, inverse: \Weather.drive)
  var weatherReadings: [Weather]?
  
  // MARK: - Private properties
  
  private var categoryRaw: Category?

  // MARK: - Computed Properties

  var startWeather: Weather? { weatherReadings?.first { $0.type == .start } }
  var endWeather: Weather? { weatherReadings?.first { $0.type == .end } }

  var category: Category {
    get { categoryRaw ?? .none }
    set { categoryRaw = newValue }
  }

  var displayName: String {
    if let name { return name }
    let timeWord = Self.timeOfDayWord(for: startedAt)
    switch (startPlaceName, endPlaceName) {
    case (let start?, let end?): return String(localized: "\(start) → \(end)", comment: "Drive name with both start and end location")
    case (let start?, nil): return String(localized: "\(timeWord) drive from \(start)", comment: "Drive name with known start location only")
    case (nil, let end?): return String(localized: "\(timeWord) drive to \(end)", comment: "Drive name with known end location only")
    case (nil, nil): return Self.timeOfDayDriveName(for: startedAt)
    }
  }

  var orderedPositions: [Position] {
    guard let positions else { return [] }
    return positions.sorted(by: { $0.timestamp < $1.timestamp })
  }

  var positionLocationCoordinatesIn2D: [CLLocationCoordinate2D] {
    orderedPositions.map(\.location.coordinate)
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
    self.categoryRaw = nil
    self.positions = nil
    self.accumulatedDistanceMetres = 0
    self.weatherReadings = nil
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
