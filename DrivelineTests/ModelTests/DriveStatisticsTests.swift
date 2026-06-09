//
//  DriveStatisticsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 09/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import SwiftData
import Testing

@Suite("Drive Statistics")
@MainActor
final class DriveStatisticsTests: SwiftDataBaseTestCase {

  // MARK: - Helpers

  private let base = Date(timeIntervalSinceReferenceDate: 0)

  private func position(
    offset: TimeInterval,
    latitude: Double = 0,
    longitude: Double = 0,
    altitude: Double = 0,
    course: Double = 0,
    speed: Double = 14
  ) -> Position {
    Position(
      timestamp: base.addingTimeInterval(offset),
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: course,
      courseAccuracy: 5,
      speed: speed,
      speedAccuracy: 1
    )
  }

  private func drive(with positions: [Position], duration: TimeInterval) -> Drive {
    let drive = Drive(name: "Test")
    drive.startedAt = base
    drive.status = .finished
    drive.endedAt = base.addingTimeInterval(duration)
    drive.positions = positions
    return drive
  }

  // MARK: - Mean / Variance / Standard Deviation

  @Test
  func meanSpeedIsZeroWithNoValidSamples() {
    let drive = Drive(name: "Test")
    #expect(drive.meanSpeedMetresPerSecond == 0)
  }

  @Test
  func meanSpeedAveragesValidSamplesOnly() {
    let positions = [
      position(offset: 0, speed: 10),
      position(offset: 1, speed: 20),
      position(offset: 2, speed: 30),
      position(offset: 3, speed: -1)
    ]
    let drive = drive(with: positions, duration: 3)
    #expect(drive.meanSpeedMetresPerSecond == 20)
  }

  @Test
  func varianceAndStandardDeviationOfSpeeds() {
    let positions = [
      position(offset: 0, speed: 10),
      position(offset: 1, speed: 20),
      position(offset: 2, speed: 30)
    ]
    let drive = drive(with: positions, duration: 2)
    // Population variance of [10,20,30] = 200/3 ≈ 66.67
    #expect(abs(drive.speedVarianceMetresPerSecondSquared - 200.0 / 3.0) < 0.0001)
    #expect(abs(drive.speedStandardDeviationMetresPerSecond - (200.0 / 3.0).squareRoot()) < 0.0001)
  }

  @Test
  func varianceIsZeroWithSingleSample() {
    let drive = drive(with: [position(offset: 0, speed: 12)], duration: 1)
    #expect(drive.speedVarianceMetresPerSecondSquared == 0)
    #expect(drive.speedStandardDeviationMetresPerSecond == 0)
  }

  // MARK: - Fraction Above High Speed (80 km/h ≈ 22.22 m/s)

  @Test
  func fractionAboveHighSpeedIsZeroWhenSlow() {
    let positions = (0...10).map { position(offset: Double($0), speed: 10) }
    let drive = drive(with: positions, duration: 10)
    #expect(drive.fractionOfTimeAboveHighSpeed == 0)
  }

  @Test
  func fractionAboveHighSpeedCountsTimeAboveThreshold() {
    // First 5s above 80 km/h (25 m/s), remaining 5s below.
    let positions = [
      position(offset: 0, speed: 25),
      position(offset: 5, speed: 25),
      position(offset: 10, speed: 10)
    ]
    let drive = drive(with: positions, duration: 10)
    // Segment [0,5) speed 25 (counts), segment [5,10) speed 25 (counts) → 10s of a 10s trip.
    #expect(abs(drive.fractionOfTimeAboveHighSpeed - 1.0) < 0.0001)
  }

  // MARK: - Sustained High-Speed Segments

  @Test
  func sustainedHighSpeedSegmentRequiresMoreThanTenSeconds() {
    // 8 seconds above threshold — not sustained.
    let positions = (0...8).map { position(offset: Double($0), speed: 30) }
    let drive = drive(with: positions, duration: 8)
    #expect(drive.sustainedHighSpeedSegmentCount == 0)
  }

  @Test
  func sustainedHighSpeedSegmentCountsLongRun() {
    let positions = (0...15).map { position(offset: Double($0), speed: 30) }
    let drive = drive(with: positions, duration: 15)
    #expect(drive.sustainedHighSpeedSegmentCount == 1)
  }

  @Test
  func sustainedHighSpeedSegmentsCountSeparateRuns() {
    var positions = (0...12).map { position(offset: Double($0), speed: 30) }
    positions += (13...15).map { position(offset: Double($0), speed: 5) }
    positions += (16...28).map { position(offset: Double($0), speed: 30) }
    let drive = drive(with: positions, duration: 28)
    #expect(drive.sustainedHighSpeedSegmentCount == 2)
  }

  // MARK: - Stops (< 5 km/h ≈ 1.39 m/s for > 10s)

  @Test
  func stopCountAndStoppedDuration() {
    // 0-12s stopped, 13-30s driving.
    var positions = (0...12).map { position(offset: Double($0), speed: 0) }
    positions += (13...30).map { position(offset: Double($0), speed: 15) }
    let drive = drive(with: positions, duration: 30)
    #expect(drive.stopCount == 1)
    #expect(drive.stoppedDurationSeconds == 12)
    #expect(abs(drive.fractionOfTimeStopped - 12.0 / 30.0) < 0.0001)
  }

  @Test
  func briefStopIsNotCounted() {
    var positions = (0...8).map { position(offset: Double($0), speed: 0) }
    positions += (9...20).map { position(offset: Double($0), speed: 15) }
    let drive = drive(with: positions, duration: 20)
    #expect(drive.stopCount == 0)
    #expect(drive.fractionOfTimeStopped == 0)
  }

  // MARK: - Sinuosity

  @Test
  func sinuosityIsZeroWithoutEndpoints() {
    let drive = Drive(name: "Test")
    #expect(drive.sinuosity == 0)
  }

  @Test
  func straightLineSinuosityIsApproximatelyOne() {
    let positions = [
      position(offset: 0, latitude: 0.0, longitude: 0.0),
      position(offset: 1, latitude: 0.05, longitude: 0.0),
      position(offset: 2, latitude: 0.1, longitude: 0.0)
    ]
    let drive = drive(with: positions, duration: 2)
    #expect(abs(drive.sinuosity - 1.0) < 0.01)
  }

  @Test
  func detourIncreasesSinuosity() {
    // Travel out east and back to near the start: long path, short straight-line distance.
    let positions = [
      position(offset: 0, latitude: 0.0, longitude: 0.0),
      position(offset: 1, latitude: 0.0, longitude: 0.1),
      position(offset: 2, latitude: 0.0, longitude: 0.001)
    ]
    let drive = drive(with: positions, duration: 2)
    #expect(drive.sinuosity > 1.5)
  }

  @Test
  func sinuosityIsZeroForRoundTrip() {
    let positions = [
      position(offset: 0, latitude: 0.0, longitude: 0.0),
      position(offset: 1, latitude: 0.1, longitude: 0.0),
      position(offset: 2, latitude: 0.0, longitude: 0.0)
    ]
    let drive = drive(with: positions, duration: 2)
    #expect(drive.sinuosity == 0)
  }

  // MARK: - Bearing Change Rate

  @Test
  func bearingChangeRateIsZeroForStraightLine() {
    let positions = [
      position(offset: 0, latitude: 0.0, longitude: 0.0),
      position(offset: 1, latitude: 0.1, longitude: 0.0),
      position(offset: 2, latitude: 0.2, longitude: 0.0)
    ]
    let drive = drive(with: positions, duration: 2)
    #expect(drive.bearingChangeRateDegreesPerKilometre < 0.01)
  }

  @Test
  func bearingChangeRateIsPositiveForTurns() {
    // North, then east — a 90° turn.
    let positions = [
      position(offset: 0, latitude: 0.0, longitude: 0.0),
      position(offset: 1, latitude: 0.1, longitude: 0.0),
      position(offset: 2, latitude: 0.1, longitude: 0.1)
    ]
    let drive = drive(with: positions, duration: 2)
    #expect(drive.bearingChangeRateDegreesPerKilometre > 0)
  }

  // MARK: - Elevation

  @Test
  func elevationGainAndLoss() {
    let positions = [
      position(offset: 0, altitude: 100),
      position(offset: 1, altitude: 150),
      position(offset: 2, altitude: 120),
      position(offset: 3, altitude: 200)
    ]
    let drive = drive(with: positions, duration: 3)
    // Gains: +50, +80 = 130. Losses: -30 = 30.
    #expect(drive.elevationGainMetres == 130)
    #expect(drive.elevationLossMetres == 30)
  }

  @Test
  func elevationIsZeroWithNoPositions() {
    let drive = Drive(name: "Test")
    #expect(drive.elevationGainMetres == 0)
    #expect(drive.elevationLossMetres == 0)
  }

  // MARK: - activeDurationSeconds

  @Test
  func activeDurationWhenRecording() throws {
    let drive = Drive(name: "Test", trigger: .automatic)
    #expect(drive.activeDurationSeconds >= 0)
    #expect(drive.activeDurationSeconds < 2)
  }

  @Test
  func activeDurationUsesEndDateWhenFinished() throws {
    let drive = Drive(name: "Test", trigger: .automatic)
    drive.status = .finished
    drive.endedAt = drive.startedAt.addingTimeInterval(600)

    #expect(drive.activeDurationSeconds == 600)
  }

  // MARK: - distanceMetres

  @Test
  func distanceMetresIsZeroWithNoPositions() throws {
    let drive = Drive(name: "Test")
    #expect(drive.distanceMetres == 0)
  }

  @Test
  func distanceMetresIsZeroForSinglePosition() throws {
    let drive = Drive(name: "Test")
    context!.insert(drive)
    let p = makePosition(latitude: 51.5, longitude: -0.1)
    context!.insert(p)
    drive.positions = (drive.positions ?? []) + [p]
    #expect(drive.distanceMetres == 0)
  }

  @Test
  func distanceMetresCalculatesBetweenTwoPoints() throws {
    let drive = Drive(name: "Test")
    context!.insert(drive)
    // 0.1 degree latitude ≈ 11,132m
    let p1 = makePosition(latitude: 0.0, longitude: 0.0)
    let p2 = makePosition(latitude: 0.1, longitude: 0.0, timestamp: .now.addingTimeInterval(60))
    context!.insert(p1)
    context!.insert(p2)
    drive.positions = [p1, p2]
    #expect(drive.distanceMetres > 11_000)
    #expect(drive.distanceMetres < 11_500)
  }

  @Test
  func distanceMetresSortsPositionsByTimestamp() throws {
    let drive = Drive(name: "Test")
    context!.insert(drive)
    let t1 = Date.now
    let t2 = t1.addingTimeInterval(60)
    let p1 = makePosition(latitude: 0.0, longitude: 0.0, timestamp: t1)
    let p2 = makePosition(latitude: 0.1, longitude: 0.0, timestamp: t2)
    context!.insert(p1)
    context!.insert(p2)
    drive.positions = [p2, p1]
    #expect(drive.distanceMetres > 11_000)
    #expect(drive.distanceMetres < 11_500)
  }

  // MARK: - maxSpeedMetresPerSecond

  @Test
  func maxSpeedIsZeroWithNilPositions() {
    let drive = Drive(name: "Test")
    #expect(drive.maxSpeedMetresPerSecond == 0)
  }

  @Test
  func maxSpeedIsZeroWithEmptyPositions() {
    let drive = Drive(name: "Test")
    drive.positions = []
    #expect(drive.maxSpeedMetresPerSecond == 0)
  }

  @Test
  func maxSpeedReturnsFastestPositionSpeed() {
    let drive = Drive(name: "Test")
    let slow = Position(latitude: 0, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 20, speedAccuracy: 1)
    let fast = Position(latitude: 0, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 50, speedAccuracy: 1)
    let medium = Position(latitude: 0, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 35, speedAccuracy: 1)
    drive.positions = [slow, fast, medium]
    #expect(drive.maxSpeedMetresPerSecond == 50)
  }

  @Test
  func maxSpeedExcludesNegativeSpeeds() {
    let drive = Drive(name: "Test")
    let valid = Position(latitude: 0, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 25, speedAccuracy: 1)
    let unavailable = Position(latitude: 0, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: -1, speedAccuracy: 0)
    drive.positions = [valid, unavailable]
    #expect(drive.maxSpeedMetresPerSecond == 25)
  }

  @Test
  func maxSpeedIsZeroWhenAllSpeedsAreNegative() {
    let drive = Drive(name: "Test")
    let unavailable = Position(latitude: 0, longitude: 0, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: -1, speedAccuracy: 0)
    drive.positions = [unavailable]
    #expect(drive.maxSpeedMetresPerSecond == 0)
  }

  // MARK: - avgSpeedMetresPerSecond

  @Test
  func avgSpeedIsZeroWhenDurationIsZero() {
    let drive = Drive(name: "Test")
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 0)
    #expect(drive.avgSpeedMetresPerSecond == 0)
  }

  @Test
  func avgSpeedIsPositiveWhenDriveHasDistanceAndDuration() throws {
    let drive = Drive(name: "Test")
    context!.insert(drive)
    let t1 = Date(timeIntervalSinceReferenceDate: 0)
    let t2 = t1.addingTimeInterval(60)
    let p1 = makePosition(latitude: 0.0, longitude: 0.0, timestamp: t1)
    let p2 = makePosition(latitude: 0.1, longitude: 0.0, timestamp: t2)
    context!.insert(p1)
    context!.insert(p2)
    drive.positions = [p1, p2]
    drive.startedAt = t1
    drive.endedAt = t2
    #expect(drive.avgSpeedMetresPerSecond > 0)
  }
}
