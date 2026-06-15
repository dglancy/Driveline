//
//  WeatherSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

@ModelActor
actor WeatherSweepService: SweepServiceProtocol {

  // MARK: - Properties

  private var weatherService: any WeatherFetchServiceProtocol = WeatherFetchService()
  nonisolated var taskIdentifier: String { Constants.Configuration.weatherSweepTaskIdentifier }

  // MARK: - Configuration

  func configure(weatherService: any WeatherFetchServiceProtocol) {
    self.weatherService = weatherService
  }

  // MARK: - Actions

  func sweep() async {
    let needsProcessing = modelContext.finishedDrives(since: Constants.Configuration.driveWeatherSweepCutoff) {
      $0.startWeather == nil || $0.endWeather == nil
    }
    guard !needsProcessing.isEmpty else { return }

    for drive in needsProcessing {
      guard !Task.isCancelled else { return }
      if drive.startWeather == nil, let first = drive.orderedPositions.first {
        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let weather = try? await weatherService.fetchWeather(at: location, type: .start, date: drive.startedAt)
        guard !Task.isCancelled else { return }
        if let weather {
          drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
        }
      }
      if drive.endWeather == nil, let last = drive.orderedPositions.last, let endedAt = drive.endedAt {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        let weather = try? await weatherService.fetchWeather(at: location, type: .end, date: endedAt)
        guard !Task.isCancelled else { return }
        if let weather {
          drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
        }
      }
      saveModelContext()
    }
  }

  // MARK: - Private

  private func saveModelContext() {
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context during weather sweep: \(error.localizedDescription)")
    }
  }
}
