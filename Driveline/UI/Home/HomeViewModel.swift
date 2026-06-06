//
//  HomeViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {

  // MARK: - Types

  struct DriveRow: Identifiable {
    let drive: Drive
    let display: DriveRowDisplay
    var id: UUID { drive.id }
  }

  struct DriveSection: Identifiable {
    var id: String { title }
    let title: String
    let rows: [DriveRow]
  }

  // MARK: - Properties

  @ObservationIgnored var modelContext: ModelContext!

  private(set) var sections: [DriveSection] = []
  private(set) var summaryLine: String?
  private(set) var isSelectMode: Bool = false
  private(set) var selectedDriveIDs: Set<UUID> = []
  private(set) var startDriveErrorMessage: String?
  private(set) var drivesToMerge: [Drive] = []

  var showingDeleteConfirmation: Bool = false
  var showingStartDriveError: Bool = false
  var showingRecordingScreen: Bool = false
  var showingMergeSheet: Bool = false

  // MARK: - Computed Properties

  var canMerge: Bool { selectedDriveIDs.count == 2 }
  var canDelete: Bool { !selectedDriveIDs.isEmpty }

  var deleteConfirmationMessage: String {
    String(localized: "\(selectedDriveIDs.count) drives and all their data will be permanently deleted.")
  }

  var selectionCountText: String {
    if selectedDriveIDs.isEmpty {
      return String(localized: "Select 2 drives to merge", comment: "Multiselect placeholder when nothing is selected")
    }
    return String(
      localized: "\(selectedDriveIDs.count) selected",
      comment: "Multiselect count of selected drives"
    )
  }

  // MARK: - Methods

  func startDrive(trigger: Drive.RecordingTrigger = .manual, using driveService: DriveRecordingService) {
    do {
      try driveService.startDrive(trigger: trigger)
    } catch {
      startDriveErrorMessage = error.localizedDescription
      showingStartDriveError = true
    }
  }

  func enterSelectMode() {
    isSelectMode = true
    selectedDriveIDs = []
  }

  func exitSelectMode() {
    isSelectMode = false
    selectedDriveIDs = []
  }

  func triggerMerge() {
    drivesToMerge = selectedDrives(from: sections).sorted { $0.startedAt < $1.startedAt }
    showingMergeSheet = true
  }

  func toggleSelection(for id: UUID) {
    if selectedDriveIDs.contains(id) {
      selectedDriveIDs.remove(id)
    } else {
      selectedDriveIDs.insert(id)
    }
  }

  func selectedDrives(from sections: [DriveSection]) -> [Drive] {
    sections.flatMap(\.rows).map(\.drive).filter { selectedDriveIDs.contains($0.id) }
  }

  func update(with drives: [Drive]) {
    sections = buildSections(from: drives)
    summaryLine = buildSummaryLine(from: drives)
  }

  func deleteDrives(_ drives: [Drive]) {
    for drive in drives {
      modelContext.delete(drive)
    }
  }

  func deleteDrives(at indexSet: IndexSet, in section: DriveSection) {
    deleteDrives(indexSet.map { section.rows[$0].drive })
  }

  func mergeDrives(orderedDrives: [Drive], mergedName: String) {
    DriveMergeService(modelContext: modelContext).merge(orderedDrives: orderedDrives, mergedName: mergedName)
  }

  // MARK: - Private

  private func buildSections(from drives: [Drive]) -> [DriveSection] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    var groupMap: [(key: String, rows: [DriveRow])] = []

    for drive in drives.sorted(by: { $0.startedAt > $1.startedAt }) {
      let key = sectionTitle(for: drive.startedAt, today: today, calendar: calendar)
      let row = DriveRow(drive: drive, display: makeDisplay(for: drive))
      if let index = groupMap.firstIndex(where: { $0.key == key }) {
        groupMap[index].rows.append(row)
      } else {
        groupMap.append((key: key, rows: [row]))
      }
    }

    return groupMap.map { DriveSection(title: $0.key, rows: $0.rows) }
  }

  private func makeDisplay(for drive: Drive) -> DriveRowDisplay {
    let duration = drive.endedAt != nil ? drive.activeDurationSeconds.localizedHoursMinutesString() : nil
    let distance = Measurement(value: drive.distanceMetres, unit: UnitLength.meters)
    return DriveRowDisplay(
      name: drive.name,
      dateTimeLabel: DriveStatsPresenter(drive: drive).startTimeLabel,
      formattedDistance: distance.localizedDistanceString(),
      formattedDuration: duration
    )
  }

  private func buildSummaryLine(from drives: [Drive]) -> String? {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
    let recent = drives.filter { $0.startedAt >= cutoff }
    guard !recent.isEmpty else { return nil }
    let totalMetres = recent.reduce(0.0) { $0 + $1.distanceMetres }
    let count = recent.count
    let distance = Measurement(value: totalMetres, unit: UnitLength.meters).localizedDistanceString()
    return String(localized: "\(count) drives · \(distance) in the last 30 days")
  }

  private func sectionTitle(for date: Date, today: Date, calendar: Calendar) -> String {
    let driveDay = calendar.startOfDay(for: date)
    let daysDiff = calendar.dateComponents([.day], from: driveDay, to: today).day ?? 0

    switch daysDiff {
    case 0:
      return String(localized: "Today")
    case 1:
      return String(localized: "Yesterday")
    case 2...6:
      return date.weekdayName()
    default:
      return date.monthAndYear()
    }
  }
}
