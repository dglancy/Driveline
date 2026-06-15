//
//  PlaceNameSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

@ModelActor
actor PlaceNameSweepService: SweepServiceProtocol {

  // MARK: - Properties

  private var geocodingService: any GeocodingServiceProtocol = GeocodingService()
  private var spotlightIndexingService: SpotlightIndexingService?
  nonisolated var taskIdentifier: String { Constants.Configuration.placeNameSweepTaskIdentifier }

  // MARK: - Configuration

  func configure(geocodingService: any GeocodingServiceProtocol) {
    self.geocodingService = geocodingService
  }

  func configure(spotlightIndexingService: SpotlightIndexingService?) {
    self.spotlightIndexingService = spotlightIndexingService
  }

  // MARK: - Actions

  func sweep() async {
    let needsProcessing = modelContext.finishedDrives(since: Constants.Configuration.drivePlaceNameSweepCutoff) {
      $0.startPlaceName == nil || $0.endPlaceName == nil
    }
    guard !needsProcessing.isEmpty else { return }

    for drive in needsProcessing {
      guard !Task.isCancelled else { return }
      if drive.startPlaceName == nil, let first = drive.orderedPositions.first {
        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let placeName = await geocodingService.reverseGeocode(location: location)
        guard !Task.isCancelled else { return }
        drive.startPlaceName = placeName
      }
      if drive.endPlaceName == nil, let last = drive.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        let placeName = await geocodingService.reverseGeocode(location: location)
        guard !Task.isCancelled else { return }
        drive.endPlaceName = placeName
      }
      saveModelContext()
      let item = SpotlightIndexingService.searchableItem(for: drive)
      await spotlightIndexingService?.indexItems([item])
    }
  }

  // MARK: - Private

  private func saveModelContext() {
    do {
      try modelContext.save()
    } catch {
      Log.ui.error("Failed to save model context during place name sweep: \(error.localizedDescription)")
    }
  }
}
