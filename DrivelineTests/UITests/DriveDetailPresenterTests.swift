//
//  DriveDetailPresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import Testing

@Suite("DriveDetailPresenter")
@MainActor
struct DriveDetailPresenterTests {

  // MARK: - Basic Properties

  @Test
  func nameReturnsDriveDisplayName() {
    let presenter = DriveDetailPresenter(drive: makeDrive(name: "Dublin to Cork"))
    #expect(presenter.name == "Dublin to Cork")
  }

  @Test
  func dateStringMatchesDriveStartedAtLongDateString() {
    let drive = makeDrive()
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.dateString == drive.startedAt.longDateString())
  }

  @Test
  func startPlaceReturnsDriveStartPlaceName() {
    let drive = makeDrive()
    drive.startPlaceName = "Home"
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.startPlace == "Home")
  }

  @Test
  func endPlaceReturnsDriveEndPlaceName() {
    let drive = makeDrive()
    drive.endPlaceName = "Office"
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.endPlace == "Office")
  }

  @Test
  func startPlaceIsNilWhenNotSet() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.startPlace == nil)
  }

  @Test
  func endPlaceIsNilWhenNotSet() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.endPlace == nil)
  }

  @Test
  func departureTimeMatchesDriveStartedAtClockString() {
    let drive = makeDrive()
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.departureTime == drive.startedAt.clockString())
  }

  @Test
  func arrivalTimeIsNilWhenDriveHasNoEndDate() {
    let drive = makeDrive()
    drive.endedAt = nil
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.arrivalTime == nil)
  }

  @Test
  func arrivalTimeMatchesDriveEndedAtClockString() {
    let drive = makeDrive()
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.arrivalTime == drive.endedAt?.clockString())
  }

  // MARK: - Category

  @Test
  func hasCategoryIsFalseWhenCategoryIsNone() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.hasCategory == false)
  }

  @Test
  func hasCategoryIsTrueWhenCategoryIsSet() {
    let drive = makeDrive()
    drive.category = .scenic
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.hasCategory == true)
  }

  @Test
  func categoryDisplayNameMatchesDriveCategory() {
    let drive = makeDrive()
    drive.category = .roadTrip
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.categoryDisplayName == Drive.Category.roadTrip.displayName)
  }

  @Test
  func triggerDisplayNameMatchesDriveTrigger() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.triggerDisplayName == Drive.RecordingTrigger.manual.displayName)
  }

  // MARK: - Route-Derived Formatting

  @Test
  func trackPointsFormatsCount() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.trackPoints(count: 0) == "0")
    #expect(presenter.trackPoints(count: 42) == "42")
  }

  @Test
  func topSpeedMatchesLocalizedSpeedString() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    let speed: CLLocationSpeed = 14
    let expected = Measurement(value: speed, unit: UnitSpeed.metersPerSecond).localizedSpeedString()
    #expect(presenter.topSpeed(maxSpeedMPS: speed) == expected)
  }

  // MARK: - Weather

  @Test
  func hasWeatherIsFalseWhenNoWeatherSet() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.hasWeather == false)
  }

  @Test
  func hasWeatherIsTrueWhenStartWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.hasWeather == true)
  }

  @Test
  func startWeatherSymbolIsNilWhenNoWeather() {
    let presenter = DriveDetailPresenter(drive: makeDrive())
    #expect(presenter.startWeatherSymbol == nil)
  }

  @Test
  func startWeatherSymbolReturnsSymbolName() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.startWeatherSymbol == "sun.max.fill")
  }

  @Test
  func startWeatherDescriptionReturnsCondition() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Partly Cloudy", symbolName: "cloud.sun.fill", type: .start)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.startWeatherDescription == "Partly Cloudy")
  }

  @Test
  func startWeatherTemperatureIsNonNilWhenWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 20.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.startWeatherTemperature != nil)
  }

  @Test
  func endWeatherSymbolReturnsSymbolName() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.endWeatherSymbol == "cloud.fill")
  }

  @Test
  func endWeatherDescriptionReturnsCondition() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.endWeatherDescription == "Cloudy")
  }

  @Test
  func endWeatherTemperatureIsNonNilWhenWeatherSet() {
    let drive = makeDrive()
    drive.weatherReadings = [Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)]
    let presenter = DriveDetailPresenter(drive: drive)
    #expect(presenter.endWeatherTemperature != nil)
  }

  // MARK: - Stats delegation to DriveStatsPresenter

  @Test
  func distanceValueAndUnitMatchStatsPresenter() {
    let drive = makeDrive()
    let stats = DriveStatsPresenter(drive: drive)
    #expect(stats.distanceValue == DriveStatsPresenter(drive: drive).distanceValue)
    #expect(stats.distanceUnit == DriveStatsPresenter(drive: drive).distanceUnit)
  }

  // MARK: - Helpers

  private func makeDrive(name: String = "Test Drive") -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 3600)
    return drive
  }
}
