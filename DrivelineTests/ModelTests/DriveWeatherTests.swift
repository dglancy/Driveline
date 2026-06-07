//
//  DriveWeatherTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 07/06/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("DriveWeather")
@MainActor
struct DriveWeatherTests {

  // MARK: - Init

  @Test
  func initSetsTemperature() {
    let weather = Weather(temperatureCelsius: 20.5, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)
    #expect(weather.temperatureCelsius == 20.5)
  }

  @Test
  func initSetsConditionDescription() {
    let weather = Weather(temperatureCelsius: 15.0, conditionDescription: "Partly Cloudy", symbolName: "cloud.sun.fill", type: .start)
    #expect(weather.conditionDescription == "Partly Cloudy")
  }

  @Test
  func initSetsSymbolName() {
    let weather = Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)
    #expect(weather.symbolName == "cloud.fill")
  }

  @Test
  func initSetsType() {
    let start = Weather(temperatureCelsius: 10.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .start)
    let end = Weather(temperatureCelsius: 8.0, conditionDescription: "Rain", symbolName: "cloud.rain.fill", type: .end)
    #expect(start.type == .start)
    #expect(end.type == .end)
  }

  @Test
  func initSetsRecordedAtToNow() {
    let before = Date.now
    let weather = Weather(temperatureCelsius: 5.0, conditionDescription: "Rain", symbolName: "cloud.rain.fill", type: .start)
    let after = Date.now
    #expect(weather.recordedAt >= before)
    #expect(weather.recordedAt <= after)
  }

  // MARK: - Drive relationship

  @Test
  func driveWeatherReadingsIsEmptyByDefault() {
    let drive = Drive()
    #expect((drive.weatherReadings ?? []).isEmpty)
  }

  @Test
  func driveStartWeatherIsNilByDefault() {
    let drive = Drive()
    #expect(drive.startWeather == nil)
  }

  @Test
  func driveEndWeatherIsNilByDefault() {
    let drive = Drive()
    #expect(drive.endWeather == nil)
  }

  @Test
  func driveStartWeatherReturnsReadingWithStartType() {
    let drive = Drive()
    let weather = Weather(temperatureCelsius: 22.0, conditionDescription: "Clear", symbolName: "sun.max.fill", type: .start)
    drive.weatherReadings = [weather]
    #expect(drive.startWeather?.temperatureCelsius == 22.0)
    #expect(drive.startWeather?.conditionDescription == "Clear")
    #expect(drive.startWeather?.symbolName == "sun.max.fill")
  }

  @Test
  func driveEndWeatherReturnsReadingWithEndType() {
    let drive = Drive()
    let weather = Weather(temperatureCelsius: 8.0, conditionDescription: "Overcast", symbolName: "cloud.fill", type: .end)
    drive.weatherReadings = [weather]
    #expect(drive.endWeather?.temperatureCelsius == 8.0)
  }

  @Test
  func driveBothWeatherReadingsCanCoexist() {
    let drive = Drive()
    let start = Weather(temperatureCelsius: 18.0, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)
    let end = Weather(temperatureCelsius: 12.0, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)
    drive.weatherReadings = [start, end]
    #expect(drive.startWeather?.temperatureCelsius == 18.0)
    #expect(drive.endWeather?.temperatureCelsius == 12.0)
  }
}
