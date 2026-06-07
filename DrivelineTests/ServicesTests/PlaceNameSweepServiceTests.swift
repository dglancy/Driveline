//
//  PlaceNameSweepServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 07/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import SwiftData
import Testing

@MainActor
final class PlaceNameSweepServiceTests: SwiftDataBaseTestCase {

  // MARK: - sweep

  @Test
  func sweepSetsEndPlaceNameForDriveWithNilEndPlaceName() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    #expect(drive.endPlaceName == "Test Place")
  }

  @Test
  func sweepSetsStartPlaceNameForDriveWithNilStartPlaceName() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    #expect(drive.startPlaceName == "Test Place")
  }

  @Test
  func sweepSkipsDrivesOlderThan30Days() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let oldDate = Date().addingTimeInterval(-2_700_000)
    try insertFinishedDrive(startedAt: oldDate, positions: [makePosition()])

    await service.sweep()

    #expect(mockGeocoding.geocodedLocations.isEmpty)
  }

  @Test
  func sweepSkipsNonFinishedDrives() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = Drive(trigger: .manual)
    drive.status = .recording
    context!.insert(drive)
    try context!.save()

    await service.sweep()

    #expect(mockGeocoding.geocodedLocations.isEmpty)
  }

  @Test
  func sweepSkipsDrivesWithBothNamesAlreadySet() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    try insertFinishedDrive(startPlaceName: "Home", endPlaceName: "Work", positions: [makePosition()])

    await service.sweep()

    #expect(mockGeocoding.geocodedLocations.isEmpty)
  }

  @Test
  func sweepLeavesNameNilWhenGeocodingFails() async throws {
    let mockGeocoding = MockGeocodingService()
    mockGeocoding.result = nil
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    #expect(drive.endPlaceName == nil)
  }

  @Test
  func sweepCompletesWithoutErrorWhenGeocodingFails() async throws {
    let mockGeocoding = MockGeocodingService()
    mockGeocoding.result = nil
    let service = makeSweepService(geocodingService: mockGeocoding)
    try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()
  }

  @Test
  func sweepDoesNotOverwriteExistingEndPlaceName() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = try insertFinishedDrive(endPlaceName: "Existing End", positions: [makePosition()])

    await service.sweep()

    #expect(drive.endPlaceName == "Existing End")
  }

  @Test
  func sweepDoesNotOverwriteExistingStartPlaceName() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = try insertFinishedDrive(startPlaceName: "Existing Start", positions: [makePosition()])

    await service.sweep()

    #expect(drive.startPlaceName == "Existing Start")
  }

  @Test
  func sweepGeocodesBothNamesWhenBothNil() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    #expect(drive.startPlaceName == "Test Place")
    #expect(drive.endPlaceName == "Test Place")
    #expect(mockGeocoding.geocodedLocations.count == 2)
  }

  @Test
  func sweepProcessesMultipleDrivesWithMissingNames() async throws {
    let mockGeocoding = MockGeocodingService()
    let service = makeSweepService(geocodingService: mockGeocoding)
    try insertFinishedDrive(positions: [makePosition()])
    try insertFinishedDrive(positions: [makePosition(latitude: 52.0, longitude: -0.2)])

    await service.sweep()

    #expect(mockGeocoding.geocodedLocations.count == 4)
  }

  // MARK: - Helpers

  private func makeSweepService(geocodingService: any GeocodingServiceProtocol = MockGeocodingService()) -> PlaceNameSweepService {
    PlaceNameSweepService(modelContext: context!, geocodingService: geocodingService)
  }

  private func makePosition(latitude: CLLocationDegrees = 51.5, longitude: CLLocationDegrees = -0.1) -> Position {
    Position(latitude: latitude, longitude: longitude, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 0, speedAccuracy: 0)
  }

  @discardableResult
  private func insertFinishedDrive(
    startedAt: Date = .now,
    startPlaceName: String? = nil,
    endPlaceName: String? = nil,
    positions: [Position] = []
  ) throws -> Drive {
    let drive = Drive(trigger: .manual)
    drive.status = .finished
    drive.startedAt = startedAt
    drive.endedAt = .now
    drive.startPlaceName = startPlaceName
    drive.endPlaceName = endPlaceName
    context!.insert(drive)
    for position in positions {
      context!.insert(position)
    }
    if !positions.isEmpty {
      drive.positions = positions
    }
    try context!.save()
    return drive
  }
}
