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

  var name: String { drive.displayName }

  var distanceValue: String { stats.distanceValue }
  var distanceUnit: String { stats.distanceUnit }
  var durationValue: String { stats.durationValue }
  var durationUnit: String { stats.durationUnit }
  var avgSpeedValue: String { stats.avgSpeedValue }
  var avgSpeedUnit: String { stats.avgSpeedUnit }

  /// Full-resolution coordinates, built once and cached. Used to fit the camera. Building this
  /// faults every `Position` in, so it must not be recomputed on each SwiftUI render.
  @ObservationIgnored private lazy var fullCoordinates: [CLLocationCoordinate2D] = drive.orderedPositions.map {
    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
  }

  /// Simplified coordinates for drawing the route polyline. The full-screen map is zoomable, so a
  /// finer tolerance is used than on the detail map to preserve shape when zoomed in.
  @ObservationIgnored private(set) lazy var coordinates: [CLLocationCoordinate2D] =
    PolylineSimplifier.simplify(fullCoordinates, toleranceMeters: 5)

  @ObservationIgnored private(set) lazy var cameraPosition: MapCameraPosition =
    .fit(to: fullCoordinates, paddingMultiplier: 2.0)

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
    self.stats = DriveStatsPresenter(drive: drive)
  }
}
