//
//  Drive+Statistics.swift
//  Driveline
//
//  Created by Damien Glancy on 09/06/2026.
//

import CoreLocation
import Foundation

extension Drive {

  // MARK: - Distance & Duration

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

  // MARK: - Speed

  var avgSpeedMetresPerSecond: CLLocationSpeed {
    guard activeDurationSeconds > 0 else { return 0 }
    return distanceMetres / activeDurationSeconds
  }

  var maxSpeedMetresPerSecond: CLLocationSpeed {
    guard let positions else { return 0 }
    let speeds = positions.compactMap { $0.speed >= 0 ? $0.speed : nil }
    return speeds.max() ?? 0
  }

  // MARK: - Speed Distribution

  /// Arithmetic mean of the valid instantaneous speed samples.
  var meanSpeedMetresPerSecond: CLLocationSpeed {
    let speeds = validSpeeds
    guard !speeds.isEmpty else { return 0 }
    return speeds.reduce(0, +) / Double(speeds.count)
  }

  /// Population variance of the valid instantaneous speed samples.
  var speedVarianceMetresPerSecondSquared: Double {
    let speeds = validSpeeds
    guard speeds.count > 1 else { return 0 }
    let mean = speeds.reduce(0, +) / Double(speeds.count)
    let sumOfSquares = speeds.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
    return sumOfSquares / Double(speeds.count)
  }

  /// Population standard deviation of the valid instantaneous speed samples.
  var speedStandardDeviationMetresPerSecond: CLLocationSpeed {
    speedVarianceMetresPerSecondSquared.squareRoot()
  }

  /// Fraction (0...1) of trip time spent above the high-speed threshold (80 km/h).
  var fractionOfTimeAboveHighSpeed: Double {
    let duration = activeDurationSeconds
    guard duration > 0 else { return 0 }
    let aboveDuration = speedSegments
      .filter { $0.speed > Constants.Statistics.highSpeedMetresPerSecond }
      .reduce(0.0) { $0 + $1.duration }
    return min(1, aboveDuration / duration)
  }

  // MARK: - High-Speed & Stop Segments

  /// Number of sustained runs (> 10s) spent above the high-speed threshold (80 km/h).
  var sustainedHighSpeedSegmentCount: Int {
    sustainedSegments(
      matching: { $0 > Constants.Statistics.highSpeedMetresPerSecond },
      minimumSeconds: Constants.Statistics.sustainedMinimumSeconds
    ).count
  }

  /// Number of stops: sustained runs (> 10s) below 5 km/h.
  var stopCount: Int {
    stopSegments.count
  }

  /// Total time spent stopped, in seconds, across all qualifying stop segments.
  var stoppedDurationSeconds: TimeInterval {
    stopSegments.reduce(0.0) { $0 + $1.upperBound.timeIntervalSince($1.lowerBound) }
  }

  /// Fraction (0...1) of trip time spent stopped.
  var fractionOfTimeStopped: Double {
    let duration = activeDurationSeconds
    guard duration > 0 else { return 0 }
    return min(1, stoppedDurationSeconds / duration)
  }

  // MARK: - Route Shape

  /// Ratio of travelled distance to straight-line start→end distance. 1 = perfectly straight.
  /// Returns 0 when the straight-line distance is not meaningful (e.g. a round trip).
  var sinuosity: Double {
    let positions = orderedPositions
    guard let first = positions.first, let last = positions.last else { return 0 }
    let straightLine = first.location.distance(from: last.location)
    guard straightLine > 0 else { return 0 }
    return distanceMetres / straightLine
  }

  /// Total absolute heading change per kilometre travelled — a proxy for corner frequency.
  var bearingChangeRateDegreesPerKilometre: Double {
    let positions = orderedPositions
    let bearings = zip(positions, positions.dropFirst())
      .compactMap { Self.bearing(from: $0.0, to: $0.1) }
    guard bearings.count > 1 else { return 0 }
    let totalChange = zip(bearings, bearings.dropFirst())
      .reduce(0.0) { $0 + Self.angularDifference($1.0, $1.1) }
    let kilometres = distanceMetres / 1000
    guard kilometres > 0 else { return 0 }
    return totalChange / kilometres
  }

  // MARK: - Elevation

  /// Total cumulative climb, in metres.
  var elevationGainMetres: Double {
    let positions = orderedPositions
    return zip(positions, positions.dropFirst()).reduce(0.0) { total, pair in
      total + max(0, pair.1.altitude - pair.0.altitude)
    }
  }

  /// Total cumulative descent, in metres (positive value).
  var elevationLossMetres: Double {
    let positions = orderedPositions
    return zip(positions, positions.dropFirst()).reduce(0.0) { total, pair in
      total + max(0, pair.0.altitude - pair.1.altitude)
    }
  }

  // MARK: - Private

  private var validSpeeds: [CLLocationSpeed] {
    orderedPositions.compactMap { $0.speed >= 0 ? $0.speed : nil }
  }

  /// Instantaneous speed paired with the duration until the next sample. Invalid speeds and
  /// non-positive intervals are dropped.
  private var speedSegments: [(speed: CLLocationSpeed, duration: TimeInterval)] {
    let positions = orderedPositions
    return zip(positions, positions.dropFirst()).compactMap { current, next in
      guard current.speed >= 0 else { return nil }
      let duration = next.timestamp.timeIntervalSince(current.timestamp)
      guard duration > 0 else { return nil }
      return (current.speed, duration)
    }
  }

  private var stopSegments: [ClosedRange<Date>] {
    sustainedSegments(
      matching: { $0 < Constants.Statistics.stoppedSpeedMetresPerSecond },
      minimumSeconds: Constants.Statistics.sustainedMinimumSeconds
    )
  }

  /// Returns the time ranges of consecutive samples whose speed satisfies `predicate` for longer
  /// than `minimumSeconds`.
  private func sustainedSegments(
    matching predicate: (CLLocationSpeed) -> Bool,
    minimumSeconds: TimeInterval
  ) -> [ClosedRange<Date>] {
    var segments: [ClosedRange<Date>] = []
    var runStart: Date?
    var runEnd: Date?

    func closeRun() {
      if let start = runStart, let end = runEnd, end.timeIntervalSince(start) > minimumSeconds {
        segments.append(start...end)
      }
      runStart = nil
      runEnd = nil
    }

    for position in orderedPositions {
      if position.speed >= 0 && predicate(position.speed) {
        if runStart == nil { runStart = position.timestamp }
        runEnd = position.timestamp
      } else {
        closeRun()
      }
    }
    closeRun()
    return segments
  }

  private static func bearing(from: Position, to: Position) -> Double? {
    let lat1 = from.latitude * .pi / 180
    let lat2 = to.latitude * .pi / 180
    let deltaLongitude = (to.longitude - from.longitude) * .pi / 180
    let y = sin(deltaLongitude) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLongitude)
    guard x != 0 || y != 0 else { return nil }
    let degrees = atan2(y, x) * 180 / .pi
    return (degrees + 360).truncatingRemainder(dividingBy: 360)
  }

  private static func angularDifference(_ first: Double, _ second: Double) -> Double {
    let difference = abs(first - second).truncatingRemainder(dividingBy: 360)
    return difference > 180 ? 360 - difference : difference
  }
}
