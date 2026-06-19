//
//  DriveDetailStateTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import SwiftData
import Testing

@Suite("DriveDetailState")
@MainActor
struct DriveDetailStateTests {

  // MARK: - Initial State

  @Test
  func coordinatesAreEmptyByDefault() {
    let model = buildModel(drive: makeDrive())
    #expect(model.coordinateSegments.isEmpty)
  }

  @Test
  func positionCountIsZeroByDefault() {
    let model = buildModel(drive: makeDrive())
    #expect(model.positionCount == 0)
  }

  @Test
  func canExportIsFalseWhenDriveHasNoPositions() {
    let model = buildModel(drive: makeDrive())
    #expect(model.canExport == false)
  }

  @Test
  func weatherAttributionIsNilByDefault() {
    let model = buildModel(drive: makeDrive())
    #expect(model.weatherAttribution == nil)
  }

  // MARK: - loadRoute

  @Test
  func coordinatesIsEmptyWhenDriveHasNoPositions() async {
    let model = buildModel(drive: makeDrive())
    await model.loadRoute()
    #expect(model.coordinateSegments.isEmpty)
  }

  @Test
  func coordinatesMatchDriveOrderedPositions() async {
    let model = buildModel(drive: driveWithOnePosition())
    await model.loadRoute()
    #expect(model.coordinateSegments.count == 1)
    #expect(model.coordinateSegments[0][0].latitude == 51.5074)
    #expect(model.coordinateSegments[0][0].longitude == -0.1278)
  }

  @Test
  func positionCountIsSetAfterLoadRoute() async {
    let model = buildModel(drive: driveWithOnePosition())
    await model.loadRoute()
    #expect(model.positionCount == 1)
  }

  @Test
  func canExportIsTrueAfterLoadRouteWithPositions() async {
    let model = buildModel(drive: driveWithOnePosition())
    await model.loadRoute()
    #expect(model.canExport == true)
  }

  @Test
  func loadRouteIsIdempotent() async {
    let model = buildModel(drive: driveWithOnePosition())
    await model.loadRoute()
    await model.loadRoute()
    #expect(model.coordinateSegments.count == 1)
  }

  // MARK: - share

  @Test
  func shareGPXProducesShareItem() async {
    let drive = driveWithOnePosition()
    let model = buildModel(drive: drive)

    await model.share(.gpx)

    #expect(model.shareItem != nil)
    #expect(model.isPreparingExport == false)
    #expect(model.showingExportError == false)
    if let url = model.shareItem?.url {
      #expect(FileManager.default.fileExists(atPath: url.path))
    }
  }

  @Test
  func shareReportsErrorWhenDriveHasNoCoordinates() async {
    let model = buildModel(drive: makeDrive())
    await model.share(.gpx)
    #expect(model.shareItem == nil)
    #expect(model.showingExportError == true)
  }

  // MARK: - Helpers

  private func makeContext() throws -> ModelContext {
    let schema = Schema([Drive.self, Position.self, Weather.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
  }

  private func buildModel(drive: Drive) -> DriveDetailState {
    let context = try! makeContext()
    context.insert(drive)
    try? context.save()
    return DriveDetailState(drive: drive, modelContainer: context.container)
  }

  private func makeDrive(name: String = "Test Drive") -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 3600)
    return drive
  }

  private func driveWithOnePosition() -> Drive {
    let drive = makeDrive()
    drive.positions = (drive.positions ?? []) + [Position(
      latitude: 51.5074,
      longitude: -0.1278,
      altitude: 11,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 270,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )]
    return drive
  }
}
