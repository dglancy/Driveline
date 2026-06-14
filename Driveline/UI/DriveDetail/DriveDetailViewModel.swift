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

// MARK: - DriveDetailViewModel

@MainActor
@Observable
final class DriveDetailViewModel {

  // MARK: - Properties

  var showingFullScreenMap = false
  var showingMoreMenu = false
  var showingDeleteConfirmation = false
  var showingEditDrive = false

  var shareItem: ShareItem?
  var isPreparingExport = false
  var showingExportError = false
  var exportErrorMessage: String?

  @ObservationIgnored let drive: Drive
  @ObservationIgnored private let stats: DriveStatsPresenter
  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored let spotlightIndexingService: SpotlightIndexingService

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

  var hasCategory: Bool { drive.category != .none }
  var categoryDisplayName: String { drive.category.displayName }

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

  var canExport: Bool { !(drive.positions?.isEmpty ?? true) }

  @ObservationIgnored private lazy var fullCoordinates: [CLLocationCoordinate2D] = drive.orderedPositions.map {
    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
  }

  @ObservationIgnored private(set) lazy var coordinates: [CLLocationCoordinate2D] =
    PolylineSimplifier.simplify(fullCoordinates, toleranceMeters: 15)

  @ObservationIgnored private(set) lazy var cameraPosition: MapCameraPosition =
    .fit(to: fullCoordinates, paddingMultiplier: 1.5)

  // MARK: - Lifecycle

  init(drive: Drive, spotlightIndexingService: SpotlightIndexingService, modelContext: ModelContext) {
    self.drive = drive
    self.stats = DriveStatsPresenter(drive: drive)
    self.spotlightIndexingService = spotlightIndexingService
    self.modelContext = modelContext
  }

  // MARK: - Actions

  func loadWeatherAttribution() {
    guard weatherAttribution == nil else { return }
    Task {
      weatherAttribution = try? await WeatherService.shared.attribution
    }
  }

  func deleteDrive() {
    DriveDeletionService(modelContext: modelContext, spotlightIndexingService: spotlightIndexingService).delete([drive])
  }

  func share(_ type: ExportFileType) async {
    guard !isPreparingExport else { return }
    isPreparingExport = true
    defer { isPreparingExport = false }
    do {
      let url = try await exporter(for: type).export(drive: drive)
      shareItem = ShareItem(url: url)
    } catch {
      exportErrorMessage = (error as? ExportError)?.errorDescription
        ?? String(localized: "Failed to prepare export. Please try again.", comment: "Generic export failure message")
      showingExportError = true
    }
  }

  // MARK: - Private

  private func exporter(for type: ExportFileType) -> any ExportingDrive {
    switch type {
    case .gpx: ExportDriveGPX()
    case .png: ExportDrivePNG()
    }
  }

  private func formatTemperature(_ celsius: Double) -> String {
    Measurement(value: celsius, unit: UnitTemperature.celsius)
      .formatted(.measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
  }
}

// MARK: - ShareItem

struct ShareItem: Identifiable {
  let id = UUID()
  let url: URL
}
