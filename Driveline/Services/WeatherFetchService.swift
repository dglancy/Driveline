//
//  WeatherFetchService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import WeatherKit

// MARK: - Protocol

@MainActor
protocol WeatherFetchServiceProtocol {
  func fetchWeather(at location: CLLocation, type: Weather.WeatherType) async throws -> Weather
}

// MARK: - WeatherFetchService

@MainActor
final class WeatherFetchService: WeatherFetchServiceProtocol {

  // MARK: - Actions

  func fetchWeather(at location: CLLocation, type: Weather.WeatherType) async throws -> Weather {
    let weather = try await WeatherService.shared.weather(for: location, including: .current)
    return Weather(
      temperatureCelsius: weather.temperature.converted(to: .celsius).value,
      conditionDescription: weather.condition.description,
      symbolName: weather.symbolName,
      type: type
    )
  }
}
