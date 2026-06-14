//
//  FullScreenMapViewModel.swift
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

@MainActor
@Observable
final class FullScreenMapViewModel {

  // MARK: - Properties

  @ObservationIgnored let drive: Drive
  @ObservationIgnored private let stats: DriveStatsPresenter
  @ObservationIgnored private let modelContainer: ModelContainer
  @ObservationIgnored private var didLoadRoute = false

  var coordinates: [CLLocationCoordinate2D] = []
  var cameraPosition: MapCameraPosition = .automatic

  // MARK: - Computed Properties

  var name: String { drive.displayName }

  var distanceValue: String { stats.distanceValue }
  var distanceUnit: String { stats.distanceUnit }
  var durationValue: String { stats.durationValue }
  var durationUnit: String { stats.durationUnit }
  var avgSpeedValue: String { stats.avgSpeedValue }
  var avgSpeedUnit: String { stats.avgSpeedUnit }

  // MARK: - Lifecycle

  init(drive: Drive, modelContainer: ModelContainer) {
    self.drive = drive
    self.stats = DriveStatsPresenter(drive: drive)
    self.modelContainer = modelContainer
  }

  // MARK: - Actions

  func loadRoute() async {
    guard !didLoadRoute else { return }
    didLoadRoute = true
    let loader = DrivePositionLoader(modelContainer: modelContainer)
    let simplified = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 5)
    coordinates = simplified
    cameraPosition = .fit(to: simplified, paddingMultiplier: 2.0)
  }
}
