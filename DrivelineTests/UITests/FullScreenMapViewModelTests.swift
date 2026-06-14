//
//  FullScreenMapViewModelTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

import Testing
import Foundation
import MapKit
import SwiftData
import SwiftUI
@testable import Driveline

@Suite("FullScreenMapViewModel")
@MainActor
struct FullScreenMapViewModelTests {

  // MARK: - name

  @Test
  func nameReturnsDriveName() {
    let vm = buildViewModel(drive: makeDrive(name: "Morning Commute"))
    #expect(vm.name == "Morning Commute")
  }

  // MARK: - coordinates

  @Test
  func coordinatesAreEmptyWithNoPositions() async {
    let vm = buildViewModel(drive: makeDrive())
    await vm.loadRoute()
    #expect(vm.coordinates.isEmpty)
  }

  @Test
  func coordinatesCountMatchesPositionCount() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0), makePosition(latitude: 38.0, longitude: -121.0)]
    let vm = buildViewModel(drive: drive)
    await vm.loadRoute()
    #expect(vm.coordinates.count == 2)
  }

  @Test
  func coordinatesPreserveLatitudeAndLongitude() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.5, longitude: -122.4)]
    let vm = buildViewModel(drive: drive)
    await vm.loadRoute()
    #expect(vm.coordinates[0].latitude == 37.5)
    #expect(vm.coordinates[0].longitude == -122.4)
  }

  // MARK: - cameraPosition

  @Test
  func cameraPositionIsAutomaticWithNoPositions() async {
    let vm = buildViewModel(drive: makeDrive())
    await vm.loadRoute()
    #expect(vm.cameraPosition == .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithSinglePosition() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0)]
    let vm = buildViewModel(drive: drive)
    await vm.loadRoute()
    #expect(vm.cameraPosition != .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithMultiplePositions() async {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0), makePosition(latitude: 38.0, longitude: -121.0)]
    let vm = buildViewModel(drive: drive)
    await vm.loadRoute()
    #expect(vm.cameraPosition != .automatic)
  }

  // MARK: - distanceValue / distanceUnit

  @Test
  func distanceValueMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.distanceValue == Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceValueString())
  }

  @Test
  func distanceUnitMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.distanceUnit == Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol())
  }

  // MARK: - durationValue

  @Test
  func durationValueMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.durationValue == drive.activeDurationSeconds.localizedHoursMinutesString())
  }

  // MARK: - avgSpeedValue / avgSpeedUnit

  @Test
  func avgSpeedValueMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.avgSpeedValue == Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString())
  }

  @Test
  func avgSpeedUnitMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.avgSpeedUnit == Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol())
  }

  // MARK: - Helpers

  private func buildViewModel(drive: Drive) -> FullScreenMapViewModel {
    let container = makeContainer()
    container.mainContext.insert(drive)
    try? container.mainContext.save()
    return FullScreenMapViewModel(drive: drive, modelContainer: container)
  }

  private func makeContainer() -> ModelContainer {
    let schema = Schema([Drive.self, Position.self, Weather.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }

  private func makeDrive(name: String = "Test Drive") -> Drive {
    Drive(name: name)
  }
}
