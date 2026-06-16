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
    #expect(drive.positions == nil || drive.positions!.isEmpty)
    #expect(drive.category == .none)
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

  // MARK: - RecordingTrigger.displayName

  @Test
  func manualTriggerDisplayName() {
    #expect(Drive.RecordingTrigger.manual.displayName == "Manually")
  }

  @Test
  func automaticTriggerDisplayName() {
    #expect(Drive.RecordingTrigger.automatic.displayName == "Automatically")
  }

  // MARK: - Category.displayName

  @Test
  func noneCategoryDisplayName() {
    #expect(Drive.Category.none.displayName == "None")
  }

  @Test
  func errandCategoryDisplayName() {
    #expect(Drive.Category.errand.displayName == "Errand")
  }

  @Test
  func urbanCategoryDisplayName() {
    #expect(Drive.Category.urban.displayName == "Urban")
  }

  @Test
  func roadTripCategoryDisplayName() {
    #expect(Drive.Category.roadTrip.displayName == "Road Trip")
  }

  @Test
  func scenicCategoryDisplayName() {
    #expect(Drive.Category.scenic.displayName == "Scenic")
  }

  @Test
  func mixedCategoryDisplayName() {
    #expect(Drive.Category.mixed.displayName == "Mixed")
  }

  // MARK: - Category.from(string:)

  @Test
  func categoryFromStringParsesErrand() {
    #expect(Drive.Category.from(string: "Errand") == .errand)
  }

  @Test
  func categoryFromStringParsesUrban() {
    #expect(Drive.Category.from(string: "Urban") == .urban)
  }

  @Test
  func categoryFromStringParsesRoadTrip() {
    #expect(Drive.Category.from(string: "Road Trip") == .roadTrip)
  }

  @Test
  func categoryFromStringParsesScenic() {
    #expect(Drive.Category.from(string: "Scenic") == .scenic)
  }

  @Test
  func categoryFromStringParsesMixed() {
    #expect(Drive.Category.from(string: "Mixed") == .mixed)
  }

  @Test
  func categoryFromStringIsCaseInsensitiveAndTrimsWhitespace() {
    #expect(Drive.Category.from(string: "  road trip  ") == .roadTrip)
  }

  @Test
  func categoryFromStringFallsBackToNoneForUnrecognizedValue() {
    #expect(Drive.Category.from(string: "Something Else") == .none)
  }

  @Test
  func categoryFromStringFallsBackToNoneForEmptyString() {
    #expect(Drive.Category.from(string: "") == .none)
  }
}
