//
//  DriveManagementState.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DriveManagementState {

  // MARK: - Properties

  var isSelectMode: Bool = false
  var selectedDriveIDs: Set<UUID> = []
  var drivesToMerge: [Drive] = []
  var showingMergeSheet: Bool = false
  var showingDeleteConfirmation: Bool = false

  // MARK: - Computed Properties

  var canMerge: Bool { selectedDriveIDs.count == 2 }
  var canDelete: Bool { !selectedDriveIDs.isEmpty }

  // MARK: - Actions

  func enterSelectMode() {
    isSelectMode = true
    selectedDriveIDs = []
  }

  func exitSelectMode() {
    isSelectMode = false
    selectedDriveIDs = []
  }

  func toggleSelection(for id: UUID) {
    if selectedDriveIDs.contains(id) {
      selectedDriveIDs.remove(id)
    } else {
      selectedDriveIDs.insert(id)
    }
  }

  func triggerMerge(from sections: [DriveSection]) {
    drivesToMerge = selectedDrives(from: sections).sorted { $0.startedAt < $1.startedAt }
    showingMergeSheet = true
  }

  func selectedDrives(from sections: [DriveSection]) -> [Drive] {
    sections.flatMap(\.rows).map(\.drive).filter { selectedDriveIDs.contains($0.id) }
  }

  func delete(_ drives: [Drive], in modelContext: ModelContext, deindexing spotlight: SpotlightIndexingService) {
    DriveDeletion.delete(drives, in: modelContext, deindexing: spotlight)
  }
}
