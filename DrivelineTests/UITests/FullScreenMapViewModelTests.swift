//
//  FullScreenMapViewModelTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 31/05/2026.
//

import Testing
import Foundation
import MapKit
import SwiftUI
@testable import Driveline

@Suite("FullScreenMapViewModel")
@MainActor
struct FullScreenMapViewModelTests {

  // MARK: - name

  @Test
  func nameReturnsDriveName() {
    let vm = FullScreenMapViewModel(drive: makeDrive(name: "Morning Commute"))
    #expect(vm.name == "Morning Commute")
  }

  // MARK: - coordinates

  @Test
  func coordinatesAreEmptyWithNoPositions() {
    let vm = FullScreenMapViewModel(drive: makeDrive())
    #expect(vm.coordinates.isEmpty)
  }

  @Test
  func coordinatesCountMatchesPositionCount() {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0), makePosition(latitude: 38.0, longitude: -121.0)]
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.coordinates.count == 2)
  }

  @Test
  func coordinatesPreserveLatitudeAndLongitude() {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.5, longitude: -122.4)]
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.coordinates[0].latitude == 37.5)
    #expect(vm.coordinates[0].longitude == -122.4)
  }

  // MARK: - cameraPosition

  @Test
  func cameraPositionIsAutomaticWithNoPositions() {
    let vm = FullScreenMapViewModel(drive: makeDrive())
    #expect(vm.cameraPosition == .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithSinglePosition() {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0)]
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.cameraPosition != .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithMultiplePositions() {
    let drive = makeDrive()
    drive.positions = [makePosition(latitude: 37.0, longitude: -122.0), makePosition(latitude: 38.0, longitude: -121.0)]
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.cameraPosition != .automatic)
  }

  // MARK: - distanceValue / distanceUnit

  @Test
  func distanceValueMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.distanceValue == Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceValueString())
  }

  @Test
  func distanceUnitMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.distanceUnit == Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol())
  }

  // MARK: - durationValue

  @Test
  func durationValueMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.durationValue == drive.activeDurationSeconds.localizedHoursMinutesString())
  }

  // MARK: - avgSpeedValue / avgSpeedUnit

  @Test
  func avgSpeedValueMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.avgSpeedValue == Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString())
  }

  @Test
  func avgSpeedUnitMatchesDriveFormatting() {
    let drive = makeDrive()
    let vm = FullScreenMapViewModel(drive: drive)
    #expect(vm.avgSpeedUnit == Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol())
  }
}

// MARK: - Helpers

private func makeDrive(name: String = "Test Drive") -> Drive {
  Drive(name: name)
}
