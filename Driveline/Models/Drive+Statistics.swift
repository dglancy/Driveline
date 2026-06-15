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
    Self.distanceMetres(for: orderedPositions)
  }

  /// Distance for display purposes. Uses the incrementally-tracked `accumulatedDistanceMetres`
  /// for finished drives (O(1)) to avoid re-walking all positions; falls back to the live
  /// `distanceMetres` walk while a drive is still recording.
  var displayDistanceMetres: Double {
    status == .finished ? accumulatedDistanceMetres : distanceMetres
  }

  var activeDurationSeconds: Double {
    max(0, (endedAt ?? .now).timeIntervalSince(startedAt))
  }

  // MARK: - Speed

  var avgSpeedMetresPerSecond: CLLocationSpeed {
    guard activeDurationSeconds > 0 else { return 0 }
    return distanceMetres / activeDurationSeconds
  }

  var displayAvgSpeedMetresPerSecond: CLLocationSpeed {
    guard activeDurationSeconds > 0 else { return 0 }
    return displayDistanceMetres / activeDurationSeconds
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
  /// The straight-line distance is floored at `Constants.Configuration.minimumLocationAccuracy`
  /// so loop drives (start ≈ end) yield a large finite value rather than dividing by ~0.
  var sinuosity: Double {
    let positions = orderedPositions
    guard let first = positions.first, let last = positions.last else { return 0 }
    let straightLine = first.location.distance(from: last.location)
    let denominator = max(straightLine, Constants.Configuration.minimumLocationAccuracy)
    return distanceMetres / denominator
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

  // MARK: - Route Statistics (single-pass)

  /// All route-derived statistics, computed from a single sorted snapshot of `orderedPositions`.
  ///
  /// Prefer this over the individual computed properties above when several statistics are
  /// needed at once (e.g. for ML feature extraction): each of those properties independently
  /// re-sorts and re-faults the full position list, which is prohibitively expensive for drives
  /// with thousands of recorded positions.
  func routeStatistics() -> RouteStatistics {
    let positions = orderedPositions
    let duration = activeDurationSeconds
    let distance = Self.distanceMetres(for: positions)

    let speed = Self.speedStatistics(for: positions)
    let segments = Self.segmentStatistics(for: positions, duration: duration)
    let shape = Self.shapeStatistics(for: positions, distanceMetres: distance)
    let elevation = Self.elevationStatistics(for: positions)

    return RouteStatistics(
      distanceMetres: distance,
      meanSpeedMetresPerSecond: speed.mean,
      speedVarianceMetresPerSecondSquared: speed.variance,
      speedStandardDeviationMetresPerSecond: speed.variance.squareRoot(),
      fractionOfTimeAboveHighSpeed: segments.fractionAboveHighSpeed,
      sustainedHighSpeedSegmentCount: segments.highSpeedSegmentCount,
      stopCount: segments.stopCount,
      stoppedDurationSeconds: segments.stoppedDuration,
      fractionOfTimeStopped: segments.fractionStopped,
      sinuosity: shape.sinuosity,
      bearingChangeRateDegreesPerKilometre: shape.bearingChangeRate,
      elevationGainMetres: elevation.gain,
      elevationLossMetres: elevation.loss
    )
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
    Self.sustainedSegments(in: orderedPositions, matching: predicate, minimumSeconds: minimumSeconds)
  }

  private static func distanceMetres(for positions: [Position]) -> Double {
    zip(positions, positions.dropFirst()).reduce(0.0) { total, pair in
      let from = CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
      let to = CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude)
      return total + from.distance(from: to)
    }
  }

  private static func speedStatistics(for positions: [Position]) -> (mean: CLLocationSpeed, variance: Double) {
    let validSpeeds = positions.compactMap { $0.speed >= 0 ? $0.speed : nil }
    let mean = validSpeeds.isEmpty ? 0 : validSpeeds.reduce(0, +) / Double(validSpeeds.count)
    guard validSpeeds.count > 1 else { return (mean, 0) }
    let sumOfSquares = validSpeeds.reduce(0.0) { $0 + ($1 - mean) * ($1 - mean) }
    return (mean, sumOfSquares / Double(validSpeeds.count))
  }

  private static func segmentStatistics(
    for positions: [Position],
    duration: TimeInterval
  ) -> (fractionAboveHighSpeed: Double, highSpeedSegmentCount: Int, stopCount: Int, stoppedDuration: TimeInterval, fractionStopped: Double) {
    let speedSegments = zip(positions, positions.dropFirst()).compactMap { current, next -> (speed: CLLocationSpeed, duration: TimeInterval)? in
      guard current.speed >= 0 else { return nil }
      let segmentDuration = next.timestamp.timeIntervalSince(current.timestamp)
      guard segmentDuration > 0 else { return nil }
      return (current.speed, segmentDuration)
    }
    let aboveHighSpeedDuration = speedSegments
      .filter { $0.speed > Constants.Statistics.highSpeedMetresPerSecond }
      .reduce(0.0) { $0 + $1.duration }
    let fractionAboveHighSpeed = duration > 0 ? min(1, aboveHighSpeedDuration / duration) : 0

    let highSpeedSegmentCount = sustainedSegments(
      in: positions,
      matching: { $0 > Constants.Statistics.highSpeedMetresPerSecond },
      minimumSeconds: Constants.Statistics.sustainedMinimumSeconds
    ).count

    let stopSegments = sustainedSegments(
      in: positions,
      matching: { $0 < Constants.Statistics.stoppedSpeedMetresPerSecond },
      minimumSeconds: Constants.Statistics.sustainedMinimumSeconds
    )
    let stoppedDuration = stopSegments.reduce(0.0) { $0 + $1.upperBound.timeIntervalSince($1.lowerBound) }
    let fractionStopped = duration > 0 ? min(1, stoppedDuration / duration) : 0

    return (fractionAboveHighSpeed, highSpeedSegmentCount, stopSegments.count, stoppedDuration, fractionStopped)
  }

  private static func shapeStatistics(for positions: [Position], distanceMetres: Double) -> (sinuosity: Double, bearingChangeRate: Double) {
    let straightLine = (positions.first.map { first in positions.last.map { first.location.distance(from: $0.location) } ?? 0 }) ?? 0
    let sinuosity = distanceMetres / max(straightLine, Constants.Configuration.minimumLocationAccuracy)

    let bearings = zip(positions, positions.dropFirst()).compactMap { bearing(from: $0.0, to: $0.1) }
    let totalBearingChange = bearings.count > 1
      ? zip(bearings, bearings.dropFirst()).reduce(0.0) { $0 + angularDifference($1.0, $1.1) }
      : 0
    let kilometres = distanceMetres / 1000
    let bearingChangeRate = kilometres > 0 ? totalBearingChange / kilometres : 0

    return (sinuosity, bearingChangeRate)
  }

  private static func elevationStatistics(for positions: [Position]) -> (gain: Double, loss: Double) {
    var gain = 0.0
    var loss = 0.0
    for (current, next) in zip(positions, positions.dropFirst()) {
      let delta = next.altitude - current.altitude
      if delta > 0 {
        gain += delta
      } else {
        loss += -delta
      }
    }
    return (gain, loss)
  }

  /// Returns the time ranges of consecutive samples whose speed satisfies `predicate` for longer
  /// than `minimumSeconds`.
  private static func sustainedSegments(
    in positions: [Position],
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

    for position in positions {
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

// MARK: - Drive.RouteStatistics

extension Drive {
  struct RouteStatistics: Sendable {
    let distanceMetres: Double
    let meanSpeedMetresPerSecond: CLLocationSpeed
    let speedVarianceMetresPerSecondSquared: Double
    let speedStandardDeviationMetresPerSecond: CLLocationSpeed
    let fractionOfTimeAboveHighSpeed: Double
    let sustainedHighSpeedSegmentCount: Int
    let stopCount: Int
    let stoppedDurationSeconds: TimeInterval
    let fractionOfTimeStopped: Double
    let sinuosity: Double
    let bearingChangeRateDegreesPerKilometre: Double
    let elevationGainMetres: Double
    let elevationLossMetres: Double
  }
}
