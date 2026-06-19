//
//  FullScreenMapState.swift
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

@MainActor
@Observable
final class FullScreenMapState {

  // MARK: - Properties

  @ObservationIgnored let drive: Drive
  @ObservationIgnored private let modelContainer: ModelContainer
  @ObservationIgnored private var didLoadRoute = false

  var coordinateSegments: [[CLLocationCoordinate2D]] = []
  var cameraPosition: MapCameraPosition = .automatic

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
    let segments = await loader.simplifiedCoordinates(forDriveID: drive.id, toleranceMeters: 5)
    coordinateSegments = segments
    cameraPosition = .fit(to: segments, paddingMultiplier: 2.0)
  }
}
