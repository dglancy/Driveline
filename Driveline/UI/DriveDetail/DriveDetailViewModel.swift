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

  var topSpeed: String { Measurement(value: maxSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedString() }
  var trackPoints: String { positionCount.formatted() }
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

  var canExport: Bool { positionCount > 0 }

  @ObservationIgnored private lazy var positionCount: Int = {
    let driveID = drive.id
    let descriptor = FetchDescriptor<Position>(predicate: #Predicate { $0.drive?.id == driveID })
    return (try? modelContext.fetchCount(descriptor)) ?? 0
  }()

  @ObservationIgnored private lazy var maxSpeedMetresPerSecond: CLLocationSpeed = {
    let driveID = drive.id
    var descriptor = FetchDescriptor<Position>(
      predicate: #Predicate { $0.drive?.id == driveID },
      sortBy: [SortDescriptor(\.speed, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    let top = (try? modelContext.fetch(descriptor))?.first?.speed ?? 0
    return max(0, top)
  }()

  var coordinates: [CLLocationCoordinate2D] = []
  var cameraPosition: MapCameraPosition = .automatic

  var modelContainer: ModelContainer { modelContext.container }

  @ObservationIgnored private var didLoadRoute = false

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

  func loadRoute() async {
    guard !didLoadRoute else { return }
    didLoadRoute = true
    let loader = DrivePositionLoader(modelContainer: modelContainer)
    let simplified = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 15)
    coordinates = simplified
    cameraPosition = .fit(to: simplified, paddingMultiplier: 1.5)
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
