//
//  WeatherFetchService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import WeatherKit

// MARK: - WeatherFetchError

enum WeatherFetchError: Error {
  case noDataAvailable
}

// MARK: - Protocol

protocol WeatherFetchServiceProtocol: Sendable {
  nonisolated func fetchWeather(at location: CLLocation, type: Weather.WeatherType) async throws -> Weather
  nonisolated func fetchWeather(at location: CLLocation, type: Weather.WeatherType, date: Date) async throws -> Weather
}

// MARK: - WeatherFetchService

final class WeatherFetchService: WeatherFetchServiceProtocol, Sendable {

  // MARK: - Actions

  nonisolated func fetchWeather(at location: CLLocation, type: Weather.WeatherType) async throws -> Weather {
    let weather = try await WeatherService.shared.weather(for: location, including: .current)
    return Weather(
      temperatureCelsius: weather.temperature.converted(to: .celsius).value,
      conditionDescription: weather.condition.description,
      symbolName: weather.symbolName,
      type: type
    )
  }

  nonisolated func fetchWeather(at location: CLLocation, type: Weather.WeatherType, date: Date) async throws -> Weather {
    let startDate = date.addingTimeInterval(-3600)
    let endDate = date.addingTimeInterval(3600)
    let hourlyForecast = try await WeatherService.shared.weather(for: location, including: .hourly(startDate: startDate, endDate: endDate))
    guard let hourWeather = hourlyForecast.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) else {
      throw WeatherFetchError.noDataAvailable
    }
    return Weather(
      temperatureCelsius: hourWeather.temperature.converted(to: .celsius).value,
      conditionDescription: hourWeather.condition.description,
      symbolName: hourWeather.symbolName,
      type: type
    )
  }
}
