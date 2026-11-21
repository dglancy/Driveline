//
//  CinematicRoutePlan.swift
//  Driveline
//
//  Created by Damien Glancy on 21/11/2026.
//

import CoreLocation
import Foundation

struct CinematicRouteSample: Sendable {
  let coordinate: CLLocationCoordinate2D
  let timestamp: Date
}

struct CinematicRouteFrame: Sendable {
  let coordinate: CLLocationCoordinate2D
  let cameraCenter: CLLocationCoordinate2D
  let heading: CLLocationDirection
  let completedSampleIndex: Int
}

struct CinematicRoutePlan: Sendable {

  // MARK: - Properties

  static let framesPerSecond = 24
  static let timeScale = 30.0
  static let maximumYawSpeed = 12.0
  static let maximumYawAcceleration = 24.0

  let samples: [CinematicRouteSample]
  let duration: TimeInterval
  let frameCount: Int

  // MARK: - Lifecycle

  init(samples: [CinematicRouteSample]) {
    self.samples = samples.sorted { $0.timestamp < $1.timestamp }
    let recordedDuration = max(0, self.samples.last?.timestamp.timeIntervalSince(self.samples.first?.timestamp ?? .now) ?? 0)
    duration = max(2, recordedDuration / Self.timeScale)
    frameCount = max(2, Int((duration * Double(Self.framesPerSecond)).rounded(.up)))
  }

  // MARK: - Actions

  func frames() -> [CinematicRouteFrame] {
    guard samples.count > 1 else {
      guard let sample = samples.first else { return [] }
      return (0..<frameCount).map { _ in
        CinematicRouteFrame(coordinate: sample.coordinate, cameraCenter: sample.coordinate, heading: 0, completedSampleIndex: 0)
      }
    }

    let rawFrames = (0..<frameCount).map(frame(at:))
    return applyCameraPhysics(to: rawFrames)
  }

  // MARK: - Private

  private func frame(at index: Int) -> CinematicRouteFrame {
    let progress = Double(index) / Double(max(frameCount - 1, 1))
    let carCoordinate = coordinate(at: progress)
    let lookAheadDuration = min(1.5, duration * 0.1)
    let lookAheadProgress = min(1, progress + (lookAheadDuration / duration))
    let lookBehindProgress = max(0, progress - (lookAheadDuration / duration))
    let directionStart = lookAheadProgress > progress ? carCoordinate : coordinate(at: lookBehindProgress)
    let directionEnd = lookAheadProgress > progress ? coordinate(at: lookAheadProgress) : carCoordinate
    let heading = bearing(from: directionStart, to: directionEnd)
    let cameraCenter = interpolate(from: carCoordinate, to: directionEnd, fraction: 0.2)
    return CinematicRouteFrame(
      coordinate: carCoordinate,
      cameraCenter: cameraCenter,
      heading: heading,
      completedSampleIndex: completedSampleIndex(at: progress)
    )
  }

  private func coordinate(at progress: Double) -> CLLocationCoordinate2D {
    let recordedDuration = samples.last?.timestamp.timeIntervalSince(samples[0].timestamp) ?? 0
    let targetDate = samples[0].timestamp.addingTimeInterval(recordedDuration * min(max(progress, 0), 1))
    let upperIndex = samples.firstIndex { $0.timestamp >= targetDate } ?? samples.index(before: samples.endIndex)
    let lowerIndex = max(0, upperIndex - 1)
    let lower = samples[lowerIndex]
    let upper = samples[upperIndex]
    let interval = upper.timestamp.timeIntervalSince(lower.timestamp)
    let fraction = interval > 0 ? targetDate.timeIntervalSince(lower.timestamp) / interval : 0
    return interpolate(from: lower.coordinate, to: upper.coordinate, fraction: fraction)
  }

  private func completedSampleIndex(at progress: Double) -> Int {
    let recordedDuration = samples.last?.timestamp.timeIntervalSince(samples[0].timestamp) ?? 0
    let targetDate = samples[0].timestamp.addingTimeInterval(recordedDuration * min(max(progress, 0), 1))
    return samples.lastIndex { $0.timestamp <= targetDate } ?? 0
  }

  private func applyCameraPhysics(to frames: [CinematicRouteFrame]) -> [CinematicRouteFrame] {
    guard var heading = frames.first?.heading,
          var cameraCenter = frames.first?.cameraCenter else { return [] }
    let frameDuration = 1 / Double(Self.framesPerSecond)
    let centerSmoothing = 1 - exp(-frameDuration / 0.65)
    var yawVelocity = 0.0

    return frames.map { frame in
      let headingDelta = shortestAngle(from: heading, to: frame.heading)
      let desiredVelocity = min(max(headingDelta * 1.5, -Self.maximumYawSpeed), Self.maximumYawSpeed)
      let maximumVelocityChange = Self.maximumYawAcceleration * frameDuration
      yawVelocity += min(max(desiredVelocity - yawVelocity, -maximumVelocityChange), maximumVelocityChange)
      var headingStep = yawVelocity * frameDuration
      if abs(headingStep) > abs(headingDelta) {
        headingStep = headingDelta
        yawVelocity = 0
      }
      heading = normalized(heading + headingStep)
      cameraCenter = interpolate(from: cameraCenter, to: frame.cameraCenter, fraction: centerSmoothing)

      return CinematicRouteFrame(
        coordinate: frame.coordinate,
        cameraCenter: cameraCenter,
        heading: heading,
        completedSampleIndex: frame.completedSampleIndex
      )
    }
  }

  private func interpolate(
    from start: CLLocationCoordinate2D,
    to end: CLLocationCoordinate2D,
    fraction: Double
  ) -> CLLocationCoordinate2D {
    let clamped = min(max(fraction, 0), 1)
    return CLLocationCoordinate2D(
      latitude: start.latitude + ((end.latitude - start.latitude) * clamped),
      longitude: start.longitude + ((end.longitude - start.longitude) * clamped)
    )
  }

  private func bearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> CLLocationDirection {
    let startLatitude = start.latitude * .pi / 180
    let endLatitude = end.latitude * .pi / 180
    let longitudeDelta = (end.longitude - start.longitude) * .pi / 180
    let y = sin(longitudeDelta) * cos(endLatitude)
    let x = cos(startLatitude) * sin(endLatitude) - sin(startLatitude) * cos(endLatitude) * cos(longitudeDelta)
    return normalized(atan2(y, x) * 180 / .pi)
  }

  private func shortestAngle(from start: Double, to end: Double) -> Double {
    (end - start + 540).truncatingRemainder(dividingBy: 360) - 180
  }

  private func normalized(_ angle: Double) -> Double {
    (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
  }
}
