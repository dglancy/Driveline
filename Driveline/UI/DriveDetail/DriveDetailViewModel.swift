//
//  DriveDetailViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftData
import SwiftUI
import WeatherKit

// MARK: - ExportedFile

struct ExportedFile: Identifiable {
  let id = UUID()
  let url: URL
}

// MARK: - DriveDetailViewModel

@MainActor
@Observable
final class DriveDetailViewModel {

  // MARK: - Properties

  var showSharingDialog = false
  var showingFullScreenMap = false
  var showingMoreMenu = false
  var showingDeleteConfirmation = false
  var showingEditDrive = false
  var exportedFile: ExportedFile?
  var exportError: String?

  @ObservationIgnored let drive: Drive
  @ObservationIgnored private let stats: DriveStatsPresenter
  @ObservationIgnored var modelContext: ModelContext?

  // MARK: - Computed Properties

  var name: String { drive.displayName }

  var dateString: String { drive.startedAt.longDateString() }

  var distanceValue: String { stats.distanceValue }
  var distanceUnit: String { stats.distanceUnit }
  var durationValue: String { stats.durationValue }
  var durationUnit: String { stats.durationUnit }
  var avgSpeedValue: String { stats.avgSpeedValue }
  var avgSpeedUnit: String { stats.avgSpeedUnit }

  var startPlace: String? { drive.startPlaceName }
  var endPlace: String? { drive.endPlaceName }

  var departureTime: String { drive.startedAt.clockString() }
  var arrivalTime: String? { drive.endedAt?.clockString() }

  var topSpeed: String { Measurement(value: drive.maxSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedString() }
  var trackPoints: String { (drive.positions?.count ?? 0).formatted() }
  var triggerDisplayName: String { drive.trigger.displayName }

  var hasWeather: Bool { drive.startWeather != nil }

  var startWeatherSymbol: String? { drive.startWeather?.symbolName }
  var startWeatherDescription: String? { drive.startWeather?.conditionDescription }
  var startWeatherTemperature: String? { drive.startWeather.map { formatTemperature($0.temperatureCelsius) } }

  var endWeatherSymbol: String? { drive.endWeather?.symbolName }
  var endWeatherDescription: String? { drive.endWeather?.conditionDescription }
  var endWeatherTemperature: String? { drive.endWeather.map { formatTemperature($0.temperatureCelsius) } }

  var weatherAttribution: WeatherAttribution?
  var weatherAttributionLightMarkURL: URL? { weatherAttribution?.combinedMarkLightURL }
  var weatherAttributionDarkMarkURL: URL? { weatherAttribution?.combinedMarkDarkURL }
  var weatherAttributionLegalURL: URL? { weatherAttribution?.legalPageURL }

  var coordinates: [CLLocationCoordinate2D] {
    drive.orderedPositions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  var cameraPosition: MapCameraPosition {
    .fit(to: coordinates, paddingMultiplier: 1.5)
  }

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
    self.stats = DriveStatsPresenter(drive: drive)
  }

  // MARK: - Actions

  func loadWeatherAttribution() {
    guard weatherAttribution == nil else { return }
    Task {
      weatherAttribution = try? await WeatherService.shared.attribution
    }
  }

  func deleteDrive() {
    guard let modelContext else { return }
    modelContext.delete(drive)
    do {
      try modelContext.save()
    } catch {
      Log.data.error("Failed to delete drive: \(error.localizedDescription)")
    }
  }

  func shareDriveGPX() {
    Task {
      do {
        let url = try await ExportDriveGPX().export(drive: drive)
        exportedFile = ExportedFile(url: url)
      } catch {
        exportError = error.localizedDescription
      }
    }
  }

  func shareDrivePNG() {
    Task {
      do {
        let url = try await ExportDrivePNG().export(drive: drive)
        exportedFile = ExportedFile(url: url)
      } catch {
        exportError = error.localizedDescription
      }
    }
  }

  // MARK: - Private

  private func formatTemperature(_ celsius: Double) -> String {
    Measurement(value: celsius, unit: UnitTemperature.celsius)
      .formatted(.measurement(width: .abbreviated, usage: .weather))
  }
}
