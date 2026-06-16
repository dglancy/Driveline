//
//  DriveDetailPresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import CoreLocation
import Foundation

struct DriveDetailPresenter {

  // MARK: - Properties

  private let drive: Drive

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
  }

  // MARK: - Computed Properties

  var name: String { drive.displayName }
  var dateString: String { drive.startedAt.longDateString() }
  var startPlace: String? { drive.startPlaceName }
  var endPlace: String? { drive.endPlaceName }
  var departureTime: String { drive.startedAt.clockString() }
  var arrivalTime: String? { drive.endedAt?.clockString() }

  var hasCategory: Bool { drive.category != .none }
  var categoryDisplayName: String { drive.category.displayName }
  var triggerDisplayName: String { drive.trigger.displayName }

  var hasWeather: Bool { drive.startWeather != nil }
  var startWeatherSymbol: String? { drive.startWeather?.symbolName }
  var startWeatherDescription: String? { drive.startWeather?.conditionDescription }
  var startWeatherTemperature: String? { drive.startWeather.map { formatTemperature($0.temperatureCelsius) } }
  var endWeatherSymbol: String? { drive.endWeather?.symbolName }
  var endWeatherDescription: String? { drive.endWeather?.conditionDescription }
  var endWeatherTemperature: String? { drive.endWeather.map { formatTemperature($0.temperatureCelsius) } }

  // MARK: - Route-Derived Formatting

  func topSpeed(maxSpeedMPS: CLLocationSpeed) -> String {
    Measurement(value: maxSpeedMPS, unit: UnitSpeed.metersPerSecond).localizedSpeedString()
  }

  func trackPoints(count: Int) -> String {
    count.formatted()
  }

  // MARK: - Private

  private func formatTemperature(_ celsius: Double) -> String {
    Measurement(value: celsius, unit: UnitTemperature.celsius)
      .formatted(.measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
  }
}
