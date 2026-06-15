//
//  DriveDetailViewModelTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import SwiftData
import Testing

@Suite("DriveDetailViewModel")
@MainActor
struct DriveDetailViewModelTests {

  // MARK: - Initial State

  @Test
  func showingFullScreenMapIsFalseByDefault() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.showingFullScreenMap == false)
  }

  // MARK: - Computed Properties

  @Test
  func nameReturnsDriveName() {
    let vm = buildViewModel(drive: makeDrive(name: "Dublin to Cork"))
    #expect(vm.name == "Dublin to Cork")
  }

  @Test
  func startPlaceReturnsDriveStartPlaceName() {
    let drive = makeDrive()
    drive.startPlaceName = "Home"
    let vm = buildViewModel(drive: drive)
    #expect(vm.startPlace == "Home")
  }

  @Test
  func endPlaceReturnsDriveEndPlaceName() {
    let drive = makeDrive()
    drive.endPlaceName = "Office"
    let vm = buildViewModel(drive: drive)
    #expect(vm.endPlace == "Office")
  }

  @Test
  func startPlaceIsNilWhenNotSet() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.startPlace == nil)
  }

  @Test
  func endPlaceIsNilWhenNotSet() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.endPlace == nil)
  }

  @Test
  func arrivalTimeIsNilWhenDriveHasNoEndDate() {
    let drive = makeDrive()
    drive.endedAt = nil
    let vm = buildViewModel(drive: drive)
    #expect(vm.arrivalTime == nil)
  }

  @Test
  func arrivalTimeIsNonNilWhenDriveHasEndDate() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.arrivalTime != nil)
  }

  @Test
  func trackPointsReflectsZeroPositionCount() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.trackPoints == "0")
  }

  @Test
  func trackPointsReflectsLoadedPositionCount() async {
    let vm = buildViewModel(drive: driveWithOnePosition())
    await vm.loadRoute()
    #expect(vm.trackPoints == "1")
  }

  @Test
  func triggerDisplayNameMatchesDriveTrigger() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.triggerDisplayName == Drive.RecordingTrigger.manual.displayName)
  }

  @Test
  func dateStringMatchesDriveStartedAtLongDateString() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.dateString == drive.startedAt.longDateString())
  }

  @Test
  func departureTimeMatchesDriveStartedAtClockString() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.departureTime == drive.startedAt.clockString())
  }

  @Test
  func arrivalTimeMatchesDriveEndedAtClockString() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    #expect(vm.arrivalTime == drive.endedAt?.clockString())
  }

  @Test
  func hasCategoryIsFalseWhenCategoryIsNone() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.hasCategory == false)
  }

  @Test
  func hasCategoryIsTrueWhenCategoryIsSet() {
    let drive = makeDrive()
    drive.category = .scenic
    let vm = buildViewModel(drive: drive)
    #expect(vm.hasCategory == true)
  }

  @Test
  func categoryDisplayNameMatchesDriveCategory() {
    let drive = makeDrive()
    drive.category = .roadTrip
    let vm = buildViewModel(drive: drive)
    #expect(vm.categoryDisplayName == Drive.Category.roadTrip.displayName)
  }

  @Test
  func topSpeedMatchesLocalizedSpeedString() async {
    let drive = driveWithOnePosition()
    let vm = buildViewModel(drive: drive)
    await vm.loadRoute()
    let expected = Measurement(value: drive.maxSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedString()
    #expect(vm.topSpeed == expected)
  }

  // MARK: - Stats delegation

  @Test
  func distanceValueAndUnitMatchStatsPresenter() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    let stats = DriveStatsPresenter(drive: drive)
    #expect(vm.distanceValue == stats.distanceValue)
    #expect(vm.distanceUnit == stats.distanceUnit)
  }

  @Test
  func durationValueAndUnitMatchStatsPresenter() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    let stats = DriveStatsPresenter(drive: drive)
    #expect(vm.durationValue == stats.durationValue)
    #expect(vm.durationUnit == stats.durationUnit)
  }

  @Test
  func avgSpeedValueAndUnitMatchStatsPresenter() {
    let drive = makeDrive()
    let vm = buildViewModel(drive: drive)
    let stats = DriveStatsPresenter(drive: drive)
    #expect(vm.avgSpeedValue == stats.avgSpeedValue)
    #expect(vm.avgSpeedUnit == stats.avgSpeedUnit)
  }

  // MARK: - Map

  @Test
  func coordinatesIsEmptyWhenDriveHasNoPositions() async {
    let vm = buildViewModel(drive: makeDrive())
    await vm.loadRoute()
    #expect(vm.coordinates.isEmpty)
  }

  @Test
  func coordinatesMatchDriveOrderedPositions() async {
    let drive = driveWithOnePosition()
    let vm = buildViewModel(drive: drive)
    await vm.loadRoute()
    #expect(vm.coordinates.count == 1)
    #expect(vm.coordinates[0].latitude == 51.5074)
    #expect(vm.coordinates[0].longitude == -0.1278)
  }

  // MARK: - Weather computed properties

  @Test
  func hasWeatherIsFalseWhenNoWeatherSet() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.hasWeather == false)
  }

  @Test
  func hasWeatherIsTrueWhenStartWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.hasWeather == true)
  }

  @Test
  func startWeatherSymbolIsNilWhenNoWeather() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.startWeatherSymbol == nil)
  }

  @Test
  func startWeatherSymbolReturnsSymbolName() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.startWeatherSymbol == "sun.max.fill")
  }

  @Test
  func startWeatherDescriptionIsNilWhenNoWeather() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.startWeatherDescription == nil)
  }

  @Test
  func startWeatherDescriptionReturnsCondition() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Partly Cloudy", symbolName: "cloud.sun.fill", type: .start)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.startWeatherDescription == "Partly Cloudy")
  }

  @Test
  func startWeatherTemperatureIsNilWhenNoWeather() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.startWeatherTemperature == nil)
  }

  @Test
  func startWeatherTemperatureIsNonNilWhenWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.startWeatherTemperature != nil)
  }

  @Test
  func endWeatherSymbolIsNilWhenNoWeather() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.endWeatherSymbol == nil)
  }

  @Test
  func endWeatherTemperatureIsNilWhenNoWeather() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.endWeatherTemperature == nil)
  }

  @Test
  func endWeatherDescriptionIsNilWhenNoWeather() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.endWeatherDescription == nil)
  }

  @Test
  func endWeatherSymbolReturnsSymbolName() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.endWeatherSymbol == "cloud.fill")
  }

  @Test
  func endWeatherDescriptionReturnsCondition() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.endWeatherDescription == "Cloudy")
  }

  @Test
  func endWeatherTemperatureIsNonNilWhenWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)]
    let vm = buildViewModel(drive: drive)
    #expect(vm.endWeatherTemperature != nil)
  }

  @Test
  func weatherAttributionIsNilByDefault() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.weatherAttribution == nil)
  }

  @Test
  func weatherAttributionLegalURLIsNilWhenNoAttribution() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.weatherAttributionLegalURL == nil)
  }

  // MARK: - Export availability

  @Test
  func canExportIsFalseWhenDriveHasNoPositions() {
    let vm = buildViewModel(drive: makeDrive())
    #expect(vm.canExport == false)
  }

  @Test
  func canExportIsTrueWhenDriveHasPositions() async {
    let vm = buildViewModel(drive: driveWithOnePosition())
    await vm.loadRoute()
    #expect(vm.canExport == true)
  }

  // MARK: - Share

  @Test
  func shareGPXProducesFileWithFriendlyName() async {
    let drive = driveWithOnePosition()
    let vm = buildViewModel(drive: drive)

    await vm.share(.gpx)

    let expectedName = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx).lastPathComponent
    #expect(vm.shareItem?.url.lastPathComponent == expectedName)
    #expect(vm.isPreparingExport == false)
    #expect(vm.showingExportError == false)
    if let url = vm.shareItem?.url {
      #expect(FileManager.default.fileExists(atPath: url.path))
    }
  }

  @Test
  func shareReportsErrorWhenDriveHasNoCoordinates() async {
    let vm = buildViewModel(drive: makeDrive())

    await vm.share(.gpx)

    #expect(vm.shareItem == nil)
    #expect(vm.showingExportError == true)
  }

  // MARK: - Delete

  @Test
  func deleteDriveRemovesDriveFromContext() throws {
    let context = try makeContext()
    let drive = makeDrive()
    context.insert(drive)
    let vm = buildViewModel(drive: drive, modelContext: context)

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
    let vm = buildViewModel(drive: drive, modelContext: context, spotlight: SpotlightIndexingService(index: mockSpotlight))

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

  private func buildViewModel(
    drive: Drive,
    modelContext: ModelContext? = nil,
    spotlight: SpotlightIndexingService = SpotlightIndexingService(index: MockSpotlightIndex())
  ) -> DriveDetailViewModel {
    let context = try! modelContext ?? makeContext()
    context.insert(drive)
    try? context.save()
    return DriveDetailViewModel(drive: drive, spotlightIndexingService: spotlight, modelContext: context)
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
