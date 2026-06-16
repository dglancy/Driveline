//
//  DriveDeletion.swift
//  Driveline
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation
import SwiftData

@MainActor
enum DriveDeletion {

  static func delete(_ drives: [Drive], in context: ModelContext, deindexing spotlight: SpotlightIndexingService) {
    guard !drives.isEmpty else { return }
    let ids = drives.map(\.id)
    for drive in drives {
      context.delete(drive)
    }
    do {
      try context.save()
    } catch {
      Log.data.error("Failed to delete drives: \(error.localizedDescription)")
    }
    Task { await spotlight.deindexDrives(ids) }
  }
}
