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
import SwiftUI

@MainActor
@Observable
final class FullScreenMapViewModel {

  // MARK: - Properties

  @ObservationIgnored let drive: Drive
  @ObservationIgnored private let stats: DriveStatsPresenter

  // MARK: - Computed Properties

  var name: String { drive.name }

  var distanceValue: String { stats.distanceValue }
  var distanceUnit: String { stats.distanceUnit }
  var durationValue: String { stats.durationValue }
  var durationUnit: String { stats.durationUnit }
  var avgSpeedValue: String { stats.avgSpeedValue }
  var avgSpeedUnit: String { stats.avgSpeedUnit }

  var coordinates: [CLLocationCoordinate2D] {
    drive.orderedPositions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  var cameraPosition: MapCameraPosition {
    .fit(to: coordinates, paddingMultiplier: 2.0)
  }

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
    self.stats = DriveStatsPresenter(drive: drive)
  }
}
