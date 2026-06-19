//
//  DrivePositionsLoaderTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 14/06/2026.
//

import Testing
import Foundation
import CoreLocation
import SwiftData
@testable import Driveline

@Suite("DrivePositionsLoader")
@MainActor
struct DrivePositionsLoaderTests {

  @Test
  func returnsEmptyForDriveWithNoPositions() async {
    let container = makeContainer()
    let drive = makeDrive()
    container.mainContext.insert(drive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let segments = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 5)
    #expect(segments.isEmpty)
  }

  @Test
  func returnsCoordinatesOrderedByTimestamp() async {
    let container = makeContainer()
    let drive = makeDrive()
    drive.positions = [
      makePosition(latitude: 38.0, longitude: -121.0, timestamp: Date(timeIntervalSinceReferenceDate: 50)),
      makePosition(latitude: 37.0, longitude: -122.0, timestamp: Date(timeIntervalSinceReferenceDate: 0))
    ]
    container.mainContext.insert(drive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let segments = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 0)
    #expect(segments.count == 1)
    #expect(segments[0].count == 2)
    #expect(segments[0][0].latitude == 37.0)
    #expect(segments[0][1].latitude == 38.0)
  }

  @Test
  func onlyReturnsCoordinatesForRequestedDrive() async {
    let container = makeContainer()
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0, timestamp: .now)]

    let otherDrive = makeDrive()
    otherDrive.positions = [makePosition(latitude: 51.5, longitude: -0.1, timestamp: .now)]

    container.mainContext.insert(drive)
    container.mainContext.insert(otherDrive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let segments = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 0)
    #expect(segments.count == 1)
    #expect(segments[0].count == 1)
    #expect(segments[0][0].latitude == 37.0)
  }

  @Test
  func splitsIntoMultipleSegmentsWhenGapExceedsThreshold() async {
    let container = makeContainer()
    let drive = makeDrive()
    let base = Date(timeIntervalSinceReferenceDate: 0)
    drive.positions = [
      makePosition(latitude: 37.0, longitude: -122.0, timestamp: base),
      makePosition(latitude: 37.001, longitude: -122.0, timestamp: base.addingTimeInterval(1)),
      makePosition(latitude: 38.0, longitude: -121.0, timestamp: base.addingTimeInterval(120))
    ]
    container.mainContext.insert(drive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let segments = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 0)
    #expect(segments.count == 2)
    #expect(segments[0].count == 2)
    #expect(segments[1].count == 1)
  }

  @Test
  func keepsSingleSegmentWhenGapIsBelowThreshold() async {
    let container = makeContainer()
    let drive = makeDrive()
    let base = Date(timeIntervalSinceReferenceDate: 0)
    drive.positions = [
      makePosition(latitude: 37.0, longitude: -122.0, timestamp: base),
      makePosition(latitude: 37.001, longitude: -122.0, timestamp: base.addingTimeInterval(59))
    ]
    container.mainContext.insert(drive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let segments = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 0)
    #expect(segments.count == 1)
    #expect(segments[0].count == 2)
  }

  // MARK: - routeData

  @Test
  func routeDataReturnsZeroCountAndSpeedForDriveWithNoPositions() async {
    let container = makeContainer()
    let drive = makeDrive()
    container.mainContext.insert(drive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let routeData = await loader.routeData(forDriveID: drive.id, toleranceMeters: 5)
    #expect(routeData.segments.isEmpty)
    #expect(routeData.positionCount == 0)
    #expect(routeData.maxSpeedMetresPerSecond == 0)
  }

  @Test
  func routeDataReturnsPositionCountAndMaxSpeed() async {
    let container = makeContainer()
    let drive = makeDrive()
    drive.positions = [
      makePosition(latitude: 37.0, longitude: -122.0, timestamp: Date(timeIntervalSinceReferenceDate: 100), speed: 5),
      makePosition(latitude: 38.0, longitude: -121.0, timestamp: Date(timeIntervalSinceReferenceDate: 200), speed: 20)
    ]
    container.mainContext.insert(drive)
    try? container.mainContext.save()

    let loader = DrivePositionsLoader(modelContainer: container)
    let routeData = await loader.routeData(forDriveID: drive.id, toleranceMeters: 0)
    #expect(routeData.positionCount == 2)
    #expect(routeData.maxSpeedMetresPerSecond == 20)
    #expect(routeData.segments.flatMap { $0 }.count == 2)
  }

  // MARK: - Helpers

  private func makeContainer() -> ModelContainer {
    let schema = Schema([Drive.self, Position.self, Weather.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }

  private func makeDrive(name: String = "Test Drive") -> Drive {
    Drive(name: name)
  }

  private func makePosition(latitude: CLLocationDegrees, longitude: CLLocationDegrees, timestamp: Date, speed: CLLocationSpeed = 0) -> Position {
    Position(
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      altitude: 0,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 0,
      courseAccuracy: 0,
      speed: speed,
      speedAccuracy: 0
    )
  }
}
