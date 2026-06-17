//
//  FullScreenMapStateTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

import Testing
import Foundation
import MapKit
import SwiftData
import SwiftUI
@testable import Driveline

@Suite("FullScreenMapState")
@MainActor
struct FullScreenMapStateTests {

  // MARK: - coordinates

  @Test
  func coordinatesAreEmptyWithNoPositions() async {
    let model = buildModel(drive: makeDrive())
    await model.loadRoute()
    #expect(model.coordinates.isEmpty)
  }

  @Test
  func coordinatesCountMatchesPositionCount() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0), makePosition(latitude: 38.0, longitude: -121.0)]
    let model = buildModel(drive: drive)
    await model.loadRoute()
    #expect(model.coordinates.count == 2)
  }

  @Test
  func coordinatesPreserveLatitudeAndLongitude() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.5, longitude: -122.4)]
    let model = buildModel(drive: drive)
    await model.loadRoute()
    #expect(model.coordinates[0].latitude == 37.5)
    #expect(model.coordinates[0].longitude == -122.4)
  }

  // MARK: - cameraPosition

  @Test
  func cameraPositionIsAutomaticWithNoPositions() async {
    let model = buildModel(drive: makeDrive())
    await model.loadRoute()
    #expect(model.cameraPosition == .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithSinglePosition() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0)]
    let model = buildModel(drive: drive)
    await model.loadRoute()
    #expect(model.cameraPosition != .automatic)
  }

  @Test
  func loadRouteIsIdempotent() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0)]
    let model = buildModel(drive: drive)
    await model.loadRoute()
    await model.loadRoute()
    #expect(model.coordinates.count == 1)
  }

  // MARK: - Helpers

  private func buildModel(drive: Drive) -> FullScreenMapState {
    let container = makeContainer()
    container.mainContext.insert(drive)
    try? container.mainContext.save()
    return FullScreenMapState(drive: drive, modelContainer: container)
  }

  private func makeContainer() -> ModelContainer {
    let schema = Schema([Drive.self, Position.self, Weather.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }

  private func makeDrive(name: String = "Test Drive") -> Drive {
    Drive(name: name)
  }

  private func makePosition(latitude: Double, longitude: Double) -> Position {
    Position(
      latitude: latitude,
      longitude: longitude,
      altitude: 50,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 0,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )
  }
}
