//
//  HomeViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {

  // MARK: - Types

  enum StatsScope {
    case last30Days, allTime
  }

  struct DriveStats {
    var driveCount: Int = 0
    var distanceValue: String = "0.0"
    var distanceUnit: String = Measurement<UnitLength>.localizedDistanceUnitSymbol()
  }

  struct DriveRow: Identifiable {
    let drive: Drive
    var id: UUID { drive.id }

    var display: DriveRowDisplay {
      let duration = drive.endedAt != nil ? drive.activeDurationSeconds.localizedHoursMinutesString() : nil
      let distance = Measurement(value: drive.displayDistanceMetres, unit: UnitLength.meters)
      return DriveRowDisplay(
        dateTimeLabel: DriveStatsPresenter(drive: drive).startTimeLabel,
        formattedDistance: distance.localizedDistanceString(),
        formattedDuration: duration,
        iconName: DriveRowDisplay.iconName(for: drive.startedAt)
      )
    }
  }

  struct DriveSection: Identifiable {
    var id: String { title }
    let title: String
    let rows: [DriveRow]
  }

  // MARK: - Properties

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let spotlightIndexingService: SpotlightIndexingService
  @ObservationIgnored private var drives: [Drive] = []

  var navigationPath: NavigationPath = NavigationPath()
  var searchText: String = "" {
    didSet {
      guard searchText != oldValue else { return }
      sections = buildSections(from: filteredDrives)
    }
  }
  private(set) var sections: [DriveSection] = []
  private(set) var statsScope: StatsScope = .last30Days
  private(set) var recentStats: DriveStats = DriveStats()
  private(set) var allTimeStats: DriveStats = DriveStats()
  private(set) var isSelectMode: Bool = false
  private(set) var selectedDriveIDs: Set<UUID> = []
  private(set) var startDriveErrorMessage: String?
  private(set) var drivesToMerge: [Drive] = []

  var showingDeleteConfirmation: Bool = false
  var showingStartDriveError: Bool = false
  var showingMergeSheet: Bool = false

  // MARK: - Lifecycle

  init(spotlightIndexingService: SpotlightIndexingService, modelContext: ModelContext) {
    self.spotlightIndexingService = spotlightIndexingService
    self.modelContext = modelContext
  }

  // MARK: - Computed Properties

  var statsDriveCount: Int { activeStats.driveCount }
  var statsDistanceValue: String { activeStats.distanceValue }
  var statsDistanceUnit: String { activeStats.distanceUnit }
  var statsScopeLabel: String {
    statsScope == .last30Days
      ? String(localized: "last 30 days", comment: "Stats scope label for recent period")
      : String(localized: "all time", comment: "Stats scope label for all drives")
  }

  var isSearchActive: Bool { !searchText.isEmpty }

  var canMerge: Bool { selectedDriveIDs.count == 2 }
  var canDelete: Bool { !selectedDriveIDs.isEmpty }

  var deleteConfirmationMessage: String {
    String(
      localized: "\(selectedDriveIDs.count) drives and all their data will be permanently deleted.",
      comment: "Confirmation message for deleting selected drives."
    )
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

  func toggleStatsScope() {
    statsScope = statsScope == .last30Days ? .allTime : .last30Days
  }

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
    self.drives = drives
    sections = buildSections(from: filteredDrives)
    buildStats(from: drives)
  }

  func deleteDrives(_ drives: [Drive]) {
    DriveDeletionService(modelContext: modelContext, spotlightIndexingService: spotlightIndexingService).delete(drives)
  }

  func deleteDrives(at indexSet: IndexSet, in section: DriveSection) {
    deleteDrives(indexSet.map { section.rows[$0].drive })
  }

  func mergeDrives(orderedDrives: [Drive], mergedName: String) {
    DriveMergeService(modelContext: modelContext, spotlightIndexingService: spotlightIndexingService).merge(orderedDrives: orderedDrives, mergedName: mergedName)
  }

  func openDrive(fromSpotlightIdentifier identifier: String) {
    guard let uuid = UUID(uuidString: identifier),
          let drive = drives.first(where: { $0.id == uuid }) else { return }
    navigationPath = NavigationPath()
    navigationPath.append(drive)
  }

  // MARK: - Private

  private var activeStats: DriveStats { statsScope == .last30Days ? recentStats : allTimeStats }

  private var filteredDrives: [Drive] {
    guard !searchText.isEmpty else { return drives }
    return drives.filter { matches($0, searchText) }
  }

  private func matches(_ drive: Drive, _ query: String) -> Bool {
    drive.displayName.localizedCaseInsensitiveContains(query) ||
      drive.startPlaceName?.localizedCaseInsensitiveContains(query) == true ||
      drive.endPlaceName?.localizedCaseInsensitiveContains(query) == true
  }

  private func buildSections(from drives: [Drive]) -> [DriveSection] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    var groupMap: [String: [DriveRow]] = [:]
    var orderedKeys: [String] = []

    for drive in drives.sorted(by: { $0.startedAt > $1.startedAt }) {
      let key = sectionTitle(for: drive.startedAt, today: today, calendar: calendar)
      let row = DriveRow(drive: drive)
      if groupMap[key] == nil {
        orderedKeys.append(key)
      }
      groupMap[key, default: []].append(row)
    }

    return orderedKeys.map { DriveSection(title: $0, rows: groupMap[$0] ?? []) }
  }

  private func buildStats(from drives: [Drive]) {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    recentStats = driveStats(from: drives.filter { $0.startedAt >= cutoff })
    allTimeStats = driveStats(from: drives)
  }

  private func driveStats(from drives: [Drive]) -> DriveStats {
    let measurement = Measurement(value: drives.reduce(0.0) { $0 + $1.displayDistanceMetres }, unit: UnitLength.meters)
    return DriveStats(
      driveCount: drives.count,
      distanceValue: measurement.localizedDistanceValueString(),
      distanceUnit: measurement.localizedDistanceUnitSymbol()
    )
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
