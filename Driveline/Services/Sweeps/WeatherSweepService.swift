//
//  WeatherSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

@MainActor
@Observable
final class WeatherSweepService: SweepServiceProtocol {

  // MARK: - Properties

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let weatherService: any WeatherFetchServiceProtocol
  nonisolated var taskIdentifier: String { Constants.Configuration.weatherSweepTaskIdentifier }

  // MARK: - Lifecycle

  init(modelContext: ModelContext, weatherService: any WeatherFetchServiceProtocol = WeatherFetchService()) {
    self.modelContext = modelContext
    self.weatherService = weatherService
  }

  // MARK: - Actions

  func sweep() async {
    let cutoff = Date().addingTimeInterval(Constants.Configuration.driveWeatherSweepCutoff)
    let descriptor = FetchDescriptor<Drive>(
      predicate: #Predicate<Drive> { drive in
        drive.startedAt >= cutoff
      }
    )
    guard let candidates = try? modelContext.fetch(descriptor) else { return }
    let needsRetry = candidates.filter {
      $0.status == .finished && ($0.startWeather == nil || $0.endWeather == nil)
    }
    guard !needsRetry.isEmpty else { return }

    for drive in needsRetry {
      if drive.startWeather == nil, let first = drive.orderedPositions.first {
        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        if let weather = try? await weatherService.fetchWeather(at: location, type: .start, date: drive.startedAt) {
          drive.weatherReadings = (drive.weatherReadings ?? []) + [weather]
        }
      }
      if drive.endWeather == nil, let last = drive.orderedPositions.last, let endedAt = drive.endedAt {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        if let weather = try? await weatherService.fetchWeather(at: location, type: .end, date: endedAt) {
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
