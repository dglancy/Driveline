//
//  MockWeatherFetchService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 07/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation

@MainActor
final class MockWeatherFetchService: WeatherFetchServiceProtocol {

  // MARK: - Properties

  private(set) var fetchedLocations: [CLLocation] = []
  var conditionDescription = "Sunny"
  var symbolName = "sun.max.fill"
  var temperatureCelsius = 18.0
  var shouldThrow = false

  // MARK: - WeatherFetchServiceProtocol

  func fetchWeather(at location: CLLocation, type: Weather.WeatherType) async throws -> Weather {
    fetchedLocations.append(location)
    if shouldThrow { throw URLError(.notConnectedToInternet) }
    return Weather(
      temperatureCelsius: temperatureCelsius,
      conditionDescription: conditionDescription,
      symbolName: symbolName,
      type: type
    )
  }
}
