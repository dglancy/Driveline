//
//  MockWeatherFetchService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 07/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation

// Test double: each test exercises it from a single sweep actor (or the main actor) at a time,
// never concurrently, so @unchecked Sendable is safe here.
final class MockWeatherFetchService: WeatherFetchServiceProtocol, @unchecked Sendable {

  // MARK: - Properties

  nonisolated(unsafe) private(set) var fetchedLocations: [CLLocation] = []
  nonisolated(unsafe) private(set) var fetchedDates: [Date] = []
  nonisolated(unsafe) var conditionDescription = "Sunny"
  nonisolated(unsafe) var symbolName = "sun.max.fill"
  nonisolated(unsafe) var temperatureCelsius = 18.0
  nonisolated(unsafe) var shouldThrow = false
  nonisolated(unsafe) var delay: Duration?

  // MARK: - WeatherFetchServiceProtocol

  nonisolated func fetchWeather(at location: CLLocation, type: Weather.WeatherType) async throws -> Weather {
    fetchedLocations.append(location)
    if shouldThrow { throw URLError(.notConnectedToInternet) }
    return Weather(
      temperatureCelsius: temperatureCelsius,
      conditionDescription: conditionDescription,
      symbolName: symbolName,
      type: type
    )
  }

  nonisolated func fetchWeather(at location: CLLocation, type: Weather.WeatherType, date: Date) async throws -> Weather {
    fetchedLocations.append(location)
    fetchedDates.append(date)
    if let delay {
      try? await Task.sleep(for: delay)
    }
    if shouldThrow { throw URLError(.notConnectedToInternet) }
    return Weather(
      temperatureCelsius: temperatureCelsius,
      conditionDescription: conditionDescription,
      symbolName: symbolName,
      type: type
    )
  }
}
