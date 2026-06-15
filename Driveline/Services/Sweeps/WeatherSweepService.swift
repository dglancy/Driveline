//
//  WeatherSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

actor WeatherSweepService: ModelActor, SweepServiceProtocol {

  // MARK: - Properties

  nonisolated let modelContainer: ModelContainer
  nonisolated let modelExecutor: any ModelExecutor
  private let weatherService: any WeatherFetchServiceProtocol
  nonisolated var taskIdentifier: String { Constants.Configuration.weatherSweepTaskIdentifier }

  // MARK: - Lifecycle

  init(modelContainer: ModelContainer, weatherService: any WeatherFetchServiceProtocol = WeatherFetchService()) {
    self.modelContainer = modelContainer
    let modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
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
