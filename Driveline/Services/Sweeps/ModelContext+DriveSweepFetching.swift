//
//  ModelContext+DriveSweepFetching.swift
//  Driveline
//
//  Created by Damien Glancy on 15/06/2026.
//

import Foundation
import SwiftData

extension ModelContext {

  nonisolated func finishedDrives(since cutoff: TimeInterval, needsProcessing: (Drive) -> Bool) -> [Drive] {
    let cutoffDate = Date().addingTimeInterval(cutoff)
    let descriptor = FetchDescriptor<Drive>(
      predicate: #Predicate<Drive> { drive in
        drive.startedAt >= cutoffDate
      }
    )
    guard let drives = try? fetch(descriptor) else { return [] }
    return drives.filter { $0.status == .finished && needsProcessing($0) }
  }
}
