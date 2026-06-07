//
//  PositionTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Testing
import Foundation
import SwiftData
import CoreLocation

@Suite("Position")
@MainActor
final class PositionTests: SwiftDataBaseTestCase {

  // MARK: - Initialization

  @Test
  func initializesWithProvidedValues() throws {
    let timestamp = Date(timeIntervalSinceReferenceDate: 0)
    let position = Position(
      timestamp: timestamp,
      latitude: 51.5074,
      longitude: -0.1278,
      altitude: 11.5,
      horizontalAccuracy: 4.0,
      verticalAccuracy: 3.0,
      course: 270.0,
      courseAccuracy: 5.0,
      speed: 13.8,
      speedAccuracy: 1.0
    )

    #expect(position.timestamp == timestamp)
    #expect(position.latitude == 51.5074)
    #expect(position.longitude == -0.1278)
    #expect(position.altitude == 11.5)
    #expect(position.horizontalAccuracy == 4.0)
    #expect(position.verticalAccuracy == 3.0)
    #expect(position.course == 270.0)
    #expect(position.courseAccuracy == 5.0)
    #expect(position.speed == 13.8)
    #expect(position.speedAccuracy == 1.0)
    #expect(position.drive == nil)
  }

  @Test
  func acceptsNegativeValuesForUnavailableFields() throws {
    let position = Position(
      latitude: 0,
      longitude: 0,
      altitude: 0,
      horizontalAccuracy: -1,
      verticalAccuracy: -1,
      course: -1,
      courseAccuracy: -1,
      speed: -1,
      speedAccuracy: -1
    )
    #expect(position.horizontalAccuracy < 0)
    #expect(position.verticalAccuracy < 0)
    #expect(position.course < 0)
    #expect(position.courseAccuracy < 0)
    #expect(position.speed < 0)
    #expect(position.speedAccuracy < 0)
  }

  // MARK: - Persistence

  @Test
  func persistsAndFetchesPosition() throws {
    let position = Position(
      latitude: 53.3498,
      longitude: -6.2603,
      altitude: 20.0,
      horizontalAccuracy: 6.0,
      verticalAccuracy: 3.0,
      course: 90.0,
      courseAccuracy: 5.0,
      speed: 8.3,
      speedAccuracy: 1.0
    )
    context!.insert(position)
    try context!.save()

    let fetched = try context!.fetch(FetchDescriptor<Position>())
    #expect(fetched.count == 1)
    #expect(fetched[0].latitude == 53.3498)
    #expect(fetched[0].longitude == -6.2603)
  }

  @Test
  func associatesWithDrive() throws {
    let drive = Drive(name: "Evening Drive", trigger: .automatic)
    context!.insert(drive)

    let position = Position(
      latitude: 51.5,
      longitude: -0.1,
      altitude: 5,
      horizontalAccuracy: 8,
      verticalAccuracy: 3,
      course: 180,
      courseAccuracy: 5,
      speed: 10,
      speedAccuracy: 1
    )
    context!.insert(position)
    drive.positions = (drive.positions ?? []) + [position]
    try context!.save()

    let fetchedDrive = try context!.fetch(FetchDescriptor<Drive>()).first!
    #expect(fetchedDrive.positions?.count == 1)
    #expect(fetchedDrive.positions?.first?.latitude == 51.5)
  }

  @Test
  func multiplePositionsAssociateWithOneDrive() throws {
    let drive = Drive(name: "Long Drive", trigger: .manual)
    context!.insert(drive)

    for i in 0..<5 {
      let position = Position(
        timestamp: .now.addingTimeInterval(Double(i)),
        latitude: 51.5 + Double(i) * 0.001,
        longitude: -0.1,
        altitude: 0,
        horizontalAccuracy: 5,
        verticalAccuracy: 3,
        course: 0,
        courseAccuracy: 5,
        speed: 10,
        speedAccuracy: 1
      )
      context!.insert(position)
      drive.positions = (drive.positions ?? []) + [position]
    }
    try context!.save()

    let fetchedDrive = try context!.fetch(FetchDescriptor<Drive>()).first!
    #expect(fetchedDrive.positions?.count == 5)
  }
  
  @Test
  func toCLLocation() async {
    let position = Position(latitude: 1.0, longitude: 1.0, altitude: 1.0, horizontalAccuracy: 1.0, verticalAccuracy: 1.0,
                            course: 1.0, courseAccuracy: 1.0, speed: 1.0, speedAccuracy: 1.0)

    #expect(position.location.coordinate.latitude == 1.0)
    #expect(position.location.coordinate.longitude == 1.0)
    #expect(position.location.altitude == 1.0)
    #expect(position.location.horizontalAccuracy == 1.0)
    #expect(position.location.verticalAccuracy == 1.0)
    #expect(position.location.course == 1.0)
    #expect(position.location.courseAccuracy == 1.0)
    #expect(position.location.speed == 1.0)
    #expect(position.location.speedAccuracy == 1.0)
  }
}
