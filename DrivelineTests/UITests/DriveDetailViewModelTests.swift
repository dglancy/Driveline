//
//  DriveDetailViewModelTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@Suite("DriveDetailViewModel")
@MainActor
struct DriveDetailViewModelTests {

  // MARK: - Initial State

  @Test
  func showingFullScreenMapIsFalseByDefault() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.showingFullScreenMap == false)
  }

  // MARK: - Computed Properties

  @Test
  func nameReturnsDriveName() {
    let vm = DriveDetailViewModel(drive: makeDrive(name: "Dublin to Cork"))
    #expect(vm.name == "Dublin to Cork")
  }

  @Test
  func startPlaceReturnsDriveStartPlaceName() {
    let drive = makeDrive()
    drive.startPlaceName = "Home"
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.startPlace == "Home")
  }

  @Test
  func endPlaceReturnsDriveEndPlaceName() {
    let drive = makeDrive()
    drive.endPlaceName = "Office"
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.endPlace == "Office")
  }

  @Test
  func startPlaceIsNilWhenNotSet() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.startPlace == nil)
  }

  @Test
  func endPlaceIsNilWhenNotSet() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.endPlace == nil)
  }

  @Test
  func arrivalTimeIsNilWhenDriveHasNoEndDate() {
    let drive = makeDrive()
    drive.endedAt = nil
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.arrivalTime == nil)
  }

  @Test
  func arrivalTimeIsNonNilWhenDriveHasEndDate() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.arrivalTime != nil)
  }

  @Test
  func trackPointsReflectsZeroPositionCount() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.trackPoints == "0")
  }

  @Test
  func triggerDisplayNameMatchesDriveTrigger() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.triggerDisplayName == Drive.RecordingTrigger.manual.displayName)
  }

  // MARK: - Weather computed properties

  @Test
  func hasWeatherIsFalseWhenNoWeatherSet() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.hasWeather == false)
  }

  @Test
  func hasWeatherIsTrueWhenStartWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.hasWeather == true)
  }

  @Test
  func startWeatherSymbolIsNilWhenNoWeather() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.startWeatherSymbol == nil)
  }

  @Test
  func startWeatherSymbolReturnsSymbolName() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.startWeatherSymbol == "sun.max.fill")
  }

  @Test
  func startWeatherDescriptionIsNilWhenNoWeather() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.startWeatherDescription == nil)
  }

  @Test
  func startWeatherDescriptionReturnsCondition() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Partly Cloudy", symbolName: "cloud.sun.fill", type: .start)]
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.startWeatherDescription == "Partly Cloudy")
  }

  @Test
  func startWeatherTemperatureIsNilWhenNoWeather() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.startWeatherTemperature == nil)
  }

  @Test
  func startWeatherTemperatureIsNonNilWhenWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.startWeatherTemperature != nil)
  }

  @Test
  func endWeatherSymbolIsNilWhenNoWeather() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.endWeatherSymbol == nil)
  }

  @Test
  func endWeatherTemperatureIsNilWhenNoWeather() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.endWeatherTemperature == nil)
  }

  @Test
  func weatherAttributionIsNilByDefault() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.weatherAttribution == nil)
  }

  @Test
  func weatherAttributionLegalURLIsNilWhenNoAttribution() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.weatherAttributionLegalURL == nil)
  }

  // MARK: - Export availability

  @Test
  func canExportIsFalseWhenDriveHasNoPositions() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.canExport == false)
  }

  @Test
  func canExportIsTrueWhenDriveHasPositions() {
    let vm = DriveDetailViewModel(drive: driveWithOnePosition())
    #expect(vm.canExport == true)
  }

  // MARK: - Export items

  @Test
  func gpxExportWrapsDrive() {
    let drive = driveWithOnePosition()
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.gpxExport.drive === drive)
  }

  @Test
  func pngExportWrapsDrive() {
    let drive = driveWithOnePosition()
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.pngExport.drive === drive)
  }

  // MARK: - Delete

  @Test
  func deleteDriveRemovesDriveFromContext() throws {
    let context = try makeContext()
    let drive = makeDrive()
    context.insert(drive)
    let vm = DriveDetailViewModel(drive: drive)
    vm.modelContext = context

    vm.deleteDrive()

    #expect(try context.fetchCount(FetchDescriptor<Drive>()) == 0)
  }

  @Test
  func deleteDriveDeindexesFromSpotlight() async throws {
    let context = try makeContext()
    let drive = makeDrive()
    let driveID = drive.id
    context.insert(drive)
    let mockSpotlight = MockSpotlightIndex()
    let vm = DriveDetailViewModel(drive: drive)
    vm.modelContext = context
    vm.spotlightIndexingService = SpotlightIndexingService(index: mockSpotlight)

    vm.deleteDrive()

    await Task.yield()
    await Task.yield()

    #expect(mockSpotlight.deletedIdentifiers == [driveID.uuidString])
  }

  // MARK: - Helpers

  private func makeContext() throws -> ModelContext {
    let schema = Schema([Drive.self, Position.self, Weather.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
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
