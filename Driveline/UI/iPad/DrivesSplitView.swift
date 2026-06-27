//
//  DrivesSplitView.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import CoreSpotlight
import SwiftData
import SwiftUI

struct DrivesSplitView: View {

  // MARK: - Properties

  @Query(sort: \Drive.startedAt, order: .reverse)
  private var drives: [Drive]

  @State private var selectedDriveID: UUID?
  @State private var searchText: String = ""
  @State private var statsScope: StatsScope = .last30Days
  @State private var managementState = DriveManagementState()

  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(\.modelContext) private var modelContext

  // MARK: - Computed Properties

  private var sections: [DriveSection] {
    DriveSectionBuilder.sections(from: drives, searchText: searchText)
  }

  private var selectedDrive: Drive? {
    guard let id = selectedDriveID else { return nil }
    return drives.first { $0.id == id }
  }

  private var recentStats: DriveStats { DriveStats.recent(from: drives) }
  private var allTimeStats: DriveStats { DriveStats.allTime(from: drives) }
  private var activeStats: DriveStats { statsScope == .last30Days ? recentStats : allTimeStats }
  private var activeStatsPresenter: HomeStatsPresenter { HomeStatsPresenter(stats: activeStats) }

  private var isSearchActive: Bool { !searchText.isEmpty }

  // MARK: - Body

  var body: some View {
    if drives.isEmpty {
      IPadEmptyStateView()
    } else {
      splitView
    }
  }

  // MARK: - Private Views

  private var splitView: some View {
    NavigationSplitView {
      ZStack(alignment: .bottom) {
        sidebarContent
          .searchable(text: $searchText, prompt: String(localized: "Search", comment: "Search field prompt"))
          .navigationTitle(String(localized: "Drives", comment: "Navigation title for drives list"))
          .toolbar { sidebarToolbar }
          .alert(
            String(localized: "Delete Drives", comment: "Delete confirmation alert title"),
            isPresented: $managementState.showingDeleteConfirmation
          ) {
            Button.delete {
              let selected = managementState.selectedDrives(from: sections)
              if let id = selectedDriveID, selected.contains(where: { $0.id == id }) {
                selectedDriveID = nil
              }
              managementState.exitSelectMode()
              managementState.delete(selected, in: modelContext, deindexing: spotlightIndexingService)
            }
            Button.cancel()
          } message: {
            Text(HomePresenter.deleteConfirmationMessage(managementState.selectedDriveIDs.count))
          }
          .sheet(isPresented: $managementState.showingMergeSheet) {
            if managementState.drivesToMerge.count == 2 {
              MergeDrivesView(
                drives: managementState.drivesToMerge,
                modelContainer: modelContext.container,
                spotlight: spotlightIndexingService,
                onMerged: { managementState.exitSelectMode() }
              )
            }
          }

        if managementState.isSelectMode {
          SelectionToolbar(
            canMerge: managementState.canMerge,
            canDelete: managementState.canDelete,
            selectionCountText: HomePresenter.selectionCountText(managementState.selectedDriveIDs.count)
          ) {
            managementState.triggerMerge(from: sections)
          } onDelete: {
            managementState.showingDeleteConfirmation = true
          }
        }
      }
    } detail: {
      if let drive = selectedDrive {
        DriveViewerView(drive: drive, modelContainer: modelContext.container)
          .id(drive.id)
      } else {
        DriveViewerPlaceholderView()
      }
    }
    .onContinueUserActivity(CSSearchableItemActionType) { activity in
      guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let uuid = UUID(uuidString: identifier) else { return }
      selectedDriveID = uuid
    }
  }

  @ViewBuilder
  private var sidebarContent: some View {
    if isSearchActive && sections.isEmpty {
      ContentUnavailableView.search
    } else {
      DriveListContent(
        sections: sections,
        managementState: managementState,
        mode: .selectionDriven(selectedID: $selectedDriveID),
        recentDriveCount: recentStats.driveCount,
        activeStatsPresenter: activeStatsPresenter,
        statsScopeLabel: HomePresenter.statsScopeLabel(statsScope),
        isSearchActive: isSearchActive,
        onStatsToggle: { statsScope = statsScope == .last30Days ? .allTime : .last30Days }
      )
    }
  }

  // MARK: - Private

  @ToolbarContentBuilder
  private var sidebarToolbar: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      if managementState.isSelectMode {
        Button.cancel { managementState.exitSelectMode() }
      }
    }

    if !managementState.isSelectMode {
      ToolbarItem(placement: .topBarTrailing) {
        Button(
          String(localized: "Select Drives", comment: "Menu item to enter multiselect mode"),
          systemImage: "checkmark.circle"
        ) {
          managementState.enterSelectMode()
        }
        .disabled(sections.isEmpty)
      }
    }
  }
}
