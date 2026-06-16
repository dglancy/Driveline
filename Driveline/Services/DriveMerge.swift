//
//  DriveMerge.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

import Foundation
import SwiftData

@MainActor
enum DriveMerge {

  static func merge(
    orderedDrives: [Drive],
    mergedName: String,
    in context: ModelContext,
    deindexing spotlight: SpotlightIndexingService
  ) {
    guard orderedDrives.count == 2 else { return }
    let first = orderedDrives[0]
    let second = orderedDrives[1]

    let merged = Drive(name: mergedName)
    merged.startedAt = first.startedAt
    merged.endedAt = second.endedAt ?? first.endedAt
    merged.status = .finished
    merged.startPlaceName = first.startPlaceName
    merged.endPlaceName = second.endPlaceName
    merged.positions = (first.positions ?? []) + (second.positions ?? [])
    merged.weatherReadings = [first.startWeather, second.endWeather].compactMap { $0 }
    merged.accumulatedDistanceMetres = merged.distanceMetres

    context.insert(merged)
    do {
      try context.save()
    } catch {
      Log.ui.error("Failed to save model context: \(error.localizedDescription)")
    }

    DriveDeletion.delete([first, second], in: context, deindexing: spotlight)
    Task { await spotlight.indexDrive(merged) }
  }
}
