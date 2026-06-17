//
//  DriveDetailState.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftData
import SwiftUI
import WeatherKit

struct ShareItem: Identifiable {
  let id = UUID()
  let url: URL
}

@MainActor
@Observable
final class DriveDetailState {

  // MARK: - Properties

  var shareItem: ShareItem?
  var isPreparingExport = false
  var showingExportError = false
  var exportErrorMessage: String?
  var weatherAttribution: WeatherAttribution?

  @ObservationIgnored let drive: Drive
  @ObservationIgnored private let modelContainer: ModelContainer
  @ObservationIgnored private var didLoadRoute = false

  private(set) var positionCount = 0
  private(set) var maxSpeedMetresPerSecond: CLLocationSpeed = 0

  var coordinates: [CLLocationCoordinate2D] = []
  var cameraPosition: MapCameraPosition = .automatic

  // MARK: - Computed Properties

  var canExport: Bool { positionCount > 0 }
  var weatherAttributionLightMarkURL: URL? { weatherAttribution?.combinedMarkLightURL }
  var weatherAttributionDarkMarkURL: URL? { weatherAttribution?.combinedMarkDarkURL }
  var weatherAttributionLegalURL: URL? { weatherAttribution?.legalPageURL }

  // MARK: - Lifecycle

  init(drive: Drive, modelContainer: ModelContainer) {
    self.drive = drive
    self.modelContainer = modelContainer
  }

  // MARK: - Actions

  func loadRoute() async {
    guard !didLoadRoute else { return }
    didLoadRoute = true
    let loader = DrivePositionsLoader(modelContainer: modelContainer)
    let routeData = await loader.routeData(forDriveID: drive.id, toleranceMeters: 15)
    coordinates = routeData.coordinates
    positionCount = routeData.positionCount
    maxSpeedMetresPerSecond = routeData.maxSpeedMetresPerSecond
    cameraPosition = .fit(to: routeData.coordinates, paddingMultiplier: 1.5)
  }

  func loadWeatherAttribution() {
    guard weatherAttribution == nil else { return }
    Task {
      weatherAttribution = try? await WeatherService.shared.attribution
    }
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
}
