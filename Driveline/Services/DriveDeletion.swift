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
    context.saveChanges("drive deletion")
    Task { await spotlight.deindexDrives(ids) }
  }
}
