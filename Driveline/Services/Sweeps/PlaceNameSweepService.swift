//
//  PlaceNameSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

@MainActor
@Observable
final class PlaceNameSweepService: SweepServiceProtocol {

  // MARK: - Properties

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let geocodingService: any GeocodingServiceProtocol
  @ObservationIgnored private let spotlightIndexingService: SpotlightIndexingService?
  nonisolated var taskIdentifier: String { Constants.Configuration.placeNameSweepTaskIdentifier }

  // MARK: - Lifecycle

  init(modelContext: ModelContext, geocodingService: any GeocodingServiceProtocol = GeocodingService(), spotlightIndexingService: SpotlightIndexingService? = nil) {
    self.modelContext = modelContext
    self.geocodingService = geocodingService
    self.spotlightIndexingService = spotlightIndexingService
  }

  // MARK: - Actions

  func sweep() async {
    let cutoff = Date().addingTimeInterval(Constants.Configuration.drivePlaceNameSweepCutoff)
    let descriptor = FetchDescriptor<Drive>(
      predicate: #Predicate<Drive> { drive in
        drive.startedAt >= cutoff
      }
    )
    guard let candidates = try? modelContext.fetch(descriptor) else { return }
    let needsRetry = candidates.filter {
      $0.status == .finished && ($0.startPlaceName == nil || $0.endPlaceName == nil)
    }
    guard !needsRetry.isEmpty else { return }

    for drive in needsRetry {
      if drive.startPlaceName == nil, let first = drive.orderedPositions.first {
        let location = CLLocation(latitude: first.latitude, longitude: first.longitude)
        drive.startPlaceName = await geocodingService.reverseGeocode(location: location)
      }
      if drive.endPlaceName == nil, let last = drive.orderedPositions.last {
        let location = CLLocation(latitude: last.latitude, longitude: last.longitude)
        drive.endPlaceName = await geocodingService.reverseGeocode(location: location)
      }
      saveModelContext()
      await spotlightIndexingService?.indexDrive(drive)
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
