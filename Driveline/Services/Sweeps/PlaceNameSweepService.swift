//
//  PlaceNameSweepService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

actor PlaceNameSweepService: ModelActor, SweepServiceProtocol {

  // MARK: - Properties

  nonisolated let modelContainer: ModelContainer
  nonisolated let modelExecutor: any ModelExecutor
  private let geocodingService: any GeocodingServiceProtocol
  private let spotlightIndexingService: SpotlightIndexingService?
  nonisolated var taskIdentifier: String { Constants.Configuration.placeNameSweepTaskIdentifier }

  // MARK: - Lifecycle

  init(modelContainer: ModelContainer, geocodingService: any GeocodingServiceProtocol = GeocodingService(), spotlightIndexingService: SpotlightIndexingService? = nil) {
    self.modelContainer = modelContainer
    let modelContext = ModelContext(modelContainer)
    self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
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
