//
//  WeatherSweepServiceTests.swift
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
final class WeatherSweepServiceTests: SwiftDataBaseTestCase {

  // MARK: - sweep

  @Test
  func sweepSetsStartWeatherForDriveWithNilStartWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    let reloaded = try reload(drive)
    #expect(reloaded.startWeather != nil)
    #expect(reloaded.startWeather?.conditionDescription == "Sunny")
  }

  @Test
  func sweepSetsEndWeatherForDriveWithNilEndWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    let reloaded = try reload(drive)
    #expect(reloaded.endWeather != nil)
    #expect(reloaded.endWeather?.conditionDescription == "Sunny")
  }

  @Test
  func sweepPassesStartedAtDateForStartWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let startDate = Date().addingTimeInterval(-3600)
    let _ = try insertFinishedDrive(startedAt: startDate, positions: [makePosition()])

    await service.sweep()

    #expect(mockWeather.fetchedDates.first?.timeIntervalSince(startDate) ?? 999 < 1)
  }

  @Test
  func sweepPassesEndedAtDateForEndWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let endDate = Date().addingTimeInterval(-300)
    let _ = try insertFinishedDrive(endedAt: endDate, positions: [makePosition()])

    await service.sweep()

    let endDateFetched = mockWeather.fetchedDates.last
    #expect(endDateFetched != nil)
    #expect(abs((endDateFetched?.timeIntervalSince(endDate)) ?? 999) < 1)
  }

  @Test
  func sweepSkipsDrivesOlderThan30Days() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let oldDate = Date().addingTimeInterval(-2_700_000)
    try insertFinishedDrive(startedAt: oldDate, positions: [makePosition()])

    await service.sweep()

    #expect(mockWeather.fetchedDates.isEmpty)
  }

  @Test
  func sweepSkipsDrivesWithCompleteWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let startWeather = Weather(temperatureCelsius: 20, conditionDescription: "Clear", symbolName: "sun.max.fill", type: .start)
    let endWeather = Weather(temperatureCelsius: 18, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)
    try insertFinishedDrive(weatherReadings: [startWeather, endWeather], positions: [makePosition()])

    await service.sweep()

    #expect(mockWeather.fetchedDates.isEmpty)
  }

  @Test
  func sweepSkipsNonFinishedDrives() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = Drive(trigger: .manual)
    drive.status = .recording
    context!.insert(drive)
    try context!.save()

    await service.sweep()

    #expect(mockWeather.fetchedDates.isEmpty)
  }

  @Test
  func sweepSkipsDrivesWithNoPositions() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    try insertFinishedDrive(positions: [])

    await service.sweep()

    #expect(mockWeather.fetchedDates.isEmpty)
  }

  @Test
  func sweepOnlyFetchesStartWeatherWhenEndAlreadyPresent() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let endWeather = Weather(temperatureCelsius: 18, conditionDescription: "Cloudy", symbolName: "cloud.fill", type: .end)
    let drive = try insertFinishedDrive(weatherReadings: [endWeather], positions: [makePosition()])

    await service.sweep()

    let reloaded = try reload(drive)
    #expect(mockWeather.fetchedDates.count == 1)
    #expect(reloaded.startWeather != nil)
    #expect(reloaded.endWeather?.conditionDescription == "Cloudy")
  }

  @Test
  func sweepOnlyFetchesEndWeatherWhenStartAlreadyPresent() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let startWeather = Weather(temperatureCelsius: 20, conditionDescription: "Sunny", symbolName: "sun.max.fill", type: .start)
    let drive = try insertFinishedDrive(weatherReadings: [startWeather], positions: [makePosition()])

    await service.sweep()

    let reloaded = try reload(drive)
    #expect(mockWeather.fetchedDates.count == 1)
    #expect(reloaded.startWeather?.conditionDescription == "Sunny")
    #expect(reloaded.endWeather != nil)
  }

  @Test
  func sweepContinuesWhenWeatherFetchThrows() async throws {
    let mockWeather = MockWeatherFetchService()
    mockWeather.shouldThrow = true
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    await service.sweep()

    #expect(drive.startWeather == nil)
    #expect(drive.endWeather == nil)
  }

  @Test
  func sweepProcessesMultipleDrivesWithMissingWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    try insertFinishedDrive(positions: [makePosition()])
    try insertFinishedDrive(positions: [makePosition(latitude: 52.0, longitude: -0.2)])

    await service.sweep()

    #expect(mockWeather.fetchedDates.count == 4)
  }

  // MARK: - Reentrancy

  @Test
  func concurrentSweepCallsAddAtMostOneStartAndEndWeather() async throws {
    let mockWeather = MockWeatherFetchService()
    mockWeather.delay = .milliseconds(50)
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    async let first = service.sweep()
    async let second = service.sweep()
    _ = await (first, second)

    let reloaded = try reload(drive)
    #expect(reloaded.weatherReadings?.filter { $0.type == .start }.count == 1)
    #expect(reloaded.weatherReadings?.filter { $0.type == .end }.count == 1)
  }

  // MARK: - Cancellation

  @Test
  func sweepDoesNotWriteWeatherWhenCancelledMidFetch() async throws {
    let mockWeather = MockWeatherFetchService()
    mockWeather.delay = .milliseconds(50)
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    let task = Task { await service.sweep() }
    await Task.yield()
    task.cancel()
    await task.value

    #expect(drive.startWeather == nil)
    #expect(drive.endWeather == nil)
  }

  @Test
  func sweepDoesNoWorkWhenTaskAlreadyCancelled() async throws {
    let mockWeather = MockWeatherFetchService()
    let service = await makeSweepService(weatherService: mockWeather)
    let drive = try insertFinishedDrive(positions: [makePosition()])

    let task = Task { await service.sweep() }
    task.cancel()
    await task.value

    #expect(mockWeather.fetchedDates.isEmpty)
    #expect(drive.startWeather == nil)
  }

  // MARK: - Helpers

  private func makeSweepService(weatherService: any WeatherFetchServiceProtocol = MockWeatherFetchService()) async -> WeatherSweepService {
    let service = WeatherSweepService(modelContainer: container!)
    await service.configure(weatherService: weatherService)
    return service
  }

  private func makePosition(latitude: CLLocationDegrees = 51.5, longitude: CLLocationDegrees = -0.1) -> Position {
    Position(latitude: latitude, longitude: longitude, altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5, course: 0, courseAccuracy: 0, speed: 0, speedAccuracy: 0)
  }

  @discardableResult
  private func insertFinishedDrive(
    startedAt: Date = .now,
    endedAt: Date = .now,
    weatherReadings: [Weather] = [],
    positions: [Position] = []
  ) throws -> Drive {
    let drive = Drive(trigger: .manual)
    drive.status = .finished
    drive.startedAt = startedAt
    drive.endedAt = endedAt
    context!.insert(drive)
    for position in positions {
      context!.insert(position)
    }
    if !positions.isEmpty {
      drive.positions = positions
    }
    for weather in weatherReadings {
      context!.insert(weather)
    }
    if !weatherReadings.isEmpty {
      drive.weatherReadings = weatherReadings
    }
    try context!.save()
    return drive
  }
}
