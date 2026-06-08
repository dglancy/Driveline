//
//  DriveTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import SwiftData
import Testing

@Suite("Drive")
@MainActor
final class DriveTests: SwiftDataBaseTestCase {

  // MARK: - Initialization

  @Test
  func initializesWithCorrectDefaults() throws {
    let drive = Drive(name: "Morning Commute")

    #expect(drive.name == "Morning Commute")
    #expect(drive.trigger == .manual)
    #expect(drive.endedAt == nil)
    #expect(drive.startPlaceName == nil)
    #expect(drive.endPlaceName == nil)
    #expect(drive.isRecording == true)
    #expect(drive.positions == nil || drive.positions!.isEmpty)
  }

  @Test
  func initializesWithAutomaticTrigger() throws {
    let drive = Drive(name: "School Run", trigger: .automatic)
    #expect(drive.trigger == .automatic)
  }

  @Test
  func eachDriveHasUniqueID() throws {
    let a = Drive(name: "Drive A", trigger: .automatic)
    let b = Drive(name: "Drive B", trigger: .automatic)
    #expect(a.id != b.id)
  }

  // MARK: - Positions

  @Test
  func positions() async {
    let drive = Drive(name: "School Run")
    let base = Date(timeIntervalSinceReferenceDate: 0)

    let p1 = Position(timestamp: base, latitude: 1.0, longitude: 1.0, altitude: 1.0, horizontalAccuracy: 1.0,
                      verticalAccuracy: 1.0, course: 1.0, courseAccuracy: 1.0, speed: 1.0, speedAccuracy: 1.0)
    let p2 = Position(timestamp: base.addingTimeInterval(1), latitude: 1.0, longitude: 1.0, altitude: 1.0,
                      horizontalAccuracy: 1.0, verticalAccuracy: 1.0, course: 1.0, courseAccuracy: 1.0,
                      speed: 1.0, speedAccuracy: 1.0)
    let p3 = Position(timestamp: base.addingTimeInterval(2), latitude: 1.0, longitude: 1.0, altitude: 1.0,
                      horizontalAccuracy: 1.0, verticalAccuracy: 1.0, course: 1.0, courseAccuracy: 1.0,
                      speed: 1.0, speedAccuracy: 1.0)
    drive.positions = [p1, p2, p3]

    let positions = drive.orderedPositions
    #expect(positions.count == 3)
    #expect(positions[0] === p1)
    #expect(positions[1] === p2)
    #expect(positions[2] === p3)
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

  // MARK: - Persistence

  @Test
  func freshContainer() async throws {
    let count = try count(where: #Predicate<Position> { _ in
      true
    })
    #expect(count == 0)
  }


  @Test
  func persistsAndFetchesDrive() throws {
    let drive = Drive(name: "Coastal Drive", trigger: .automatic)
    context!.insert(drive)
    try context!.save()

    let fetched = try context!.fetch(FetchDescriptor<Drive>())
    #expect(fetched.count == 1)
    #expect(fetched[0].name == "Coastal Drive")
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

  // MARK: - Persistence

  @Test
  func deletingDriveCascadesToPositions() throws {
    let drive = Drive(name: "Test", trigger: .manual)
    context!.insert(drive)

    let position = Position(
      latitude: 51.5,
      longitude: -0.1,
      altitude: 10,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 0,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )
    context!.insert(position)
    drive.positions = (drive.positions ?? []) + [position]
    try context!.save()

    context!.delete(drive)
    try context!.save()

    #expect(try context!.fetch(FetchDescriptor<Drive>()).isEmpty)
    #expect(try context!.fetch(FetchDescriptor<Position>()).isEmpty)
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

  // MARK: - positionLocationCoordinatesIn2D

  @Test
  func positionLocationCoordinatesIsEmptyWithNoPositions() {
    let drive = Drive(name: "Test")
    #expect(drive.positionLocationCoordinatesIn2D.isEmpty)
  }

  @Test
  func positionLocationCoordinatesCountMatchesPositionCount() {
    let drive = Drive(name: "Test")
    drive.positions = [
      makePosition(latitude: 37.0, longitude: -122.0),
      makePosition(latitude: 38.0, longitude: -121.0)
    ]
    #expect(drive.positionLocationCoordinatesIn2D.count == 2)
  }

  @Test
  func positionLocationCoordinatesPreservesLatitudeAndLongitude() {
    let drive = Drive(name: "Test")
    drive.positions = [makePosition(latitude: 37.5, longitude: -122.4)]
    let coords = drive.positionLocationCoordinatesIn2D
    #expect(coords[0].latitude == 37.5)
    #expect(coords[0].longitude == -122.4)
  }

  // MARK: - RecordingTrigger.displayName

  @Test
  func manualTriggerDisplayName() {
    #expect(Drive.RecordingTrigger.manual.displayName == "Manually")
  }

  @Test
  func automaticTriggerDisplayName() {
    #expect(Drive.RecordingTrigger.automatic.displayName == "Automatically")
  }
}
