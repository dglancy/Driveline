//
//  Weather.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import Foundation
import SwiftData

@Model
final class Weather {

  // MARK: - Types

  enum WeatherType: String, Codable {
    case start
    case end
  }

  // MARK: - Properties

  var temperatureCelsius: Double = 0
  var conditionDescription: String = ""
  var symbolName: String = ""
  var type: WeatherType = WeatherType.start
  var recordedAt: Date = Date()
  var drive: Drive?

  // MARK: - Lifecycle

  init(temperatureCelsius: Double, conditionDescription: String, symbolName: String, type: WeatherType) {
    self.temperatureCelsius = temperatureCelsius
    self.conditionDescription = conditionDescription
    self.symbolName = symbolName
    self.type = type
    self.recordedAt = .now
  }
}
