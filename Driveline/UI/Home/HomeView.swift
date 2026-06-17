//
//  HomeView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreSpotlight
import SwiftUI
import SwiftData
import TipKit

struct HomeView: View {

  // MARK: - Properties

  @Environment(DriveRecordingService.self) private var driveService
  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(\.modelContext) private var modelContext
  @Environment(\.openURL) private var openURL

  @Query(sort: \Drive.startedAt, order: .reverse)
  private var drives: [Drive]

  @State private var navigationPath: NavigationPath = NavigationPath()
  @State private var searchText: String = ""
  @State private var statsScope: StatsScope = .last30Days
  @State private var isSelectMode: Bool = false
  @State private var selectedDriveIDs: Set<UUID> = []
  @State private var drivesToMerge: [Drive] = []
  @State private var showingDeleteConfirmation: Bool = false
  @State private var showingMergeSheet: Bool = false

  // MARK: - Computed Properties

  private var sections: [DriveSection] {
    DriveSectionBuilder.sections(from: drives, searchText: searchText)
  }

  private var recentStats: DriveStats { DriveStats.recent(from: drives) }
  private var allTimeStats: DriveStats { DriveStats.allTime(from: drives) }
  private var activeStats: DriveStats { statsScope == .last30Days ? recentStats : allTimeStats }
  private var activeStatsPresenter: HomeStatsPresenter { HomeStatsPresenter(stats: activeStats) }

  private var isSearchActive: Bool { !searchText.isEmpty }
  private var canMerge: Bool { selectedDriveIDs.count == 2 }
  private var canDelete: Bool { !selectedDriveIDs.isEmpty }

  // MARK: - Body

  var body: some View {
    NavigationStack(path: $navigationPath) {
      content
        .navigationTitle("Drives")
        .searchable(text: $searchText, prompt: "Search")
        .searchDictationBehavior(.inline(activation: .onSelect))
        .toolbar {
          HomeToolbar(
            isSelectMode: isSelectMode,
            isSectionsEmpty: sections.isEmpty,
            onExitSelectMode: exitSelectMode,
            onEnterSelectMode: enterSelectMode,
            onOpenSettings: {
              if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
              }
            },
            onRecord: { startDrive() }
          )
        }
        .onChange(of: driveService.isRecording, initial: true) { _, isRecording in
          if isRecording { exitSelectMode() }
          StatsPanelTip.isRecording = isRecording
        }
        .onChange(of: recentStats.driveCount, initial: true) { _, count in
          StatsPanelTip.driveCount = count
        }
    }
    .onContinueUserActivity(CSSearchableItemActionType) { activity in
      guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
      openDrive(fromSpotlightIdentifier: identifier)
    }
    .modifier(RecordingScreenModifier())
    .alert(
      String(localized: "Delete Drives", comment: "Delete confirmation alert title"),
      isPresented: $showingDeleteConfirmation
    ) {
      Button.delete {
        let selected = selectedDrives()
        exitSelectMode()
        deleteDrives(selected)
      }
      Button.cancel()
    } message: {
      Text(HomePresenter.deleteConfirmationMessage(selectedDriveIDs.count))
    }
    .sheet(isPresented: $showingMergeSheet) {
      if drivesToMerge.count == 2 {
        MergeDrivesView(drives: drivesToMerge) { orderedDrives, mergedName in
          mergeDrives(orderedDrives: orderedDrives, mergedName: mergedName)
        }
      }
    }
  }

  // MARK: - Private Views

  @ViewBuilder
  private var content: some View {
    if sections.isEmpty {
      if !isSearchActive {
        emptyState
      } else {
        ContentUnavailableView.search
      }
    } else {
      driveList
    }
  }

  private var emptyState: some View {
    ContentUnavailableView(
      "No Drives",
      systemImage: Icons.Widgets.car,
      description: Text(String(localized: "Your recorded drives will appear here.", comment: "Empty state description shown on the home screen when no drives have been recorded yet"))
    )
  }

  private var driveList: some View {
    ZStack(alignment: .bottom) {
      List {
        if recentStats.driveCount > 0 && !isSelectMode && !isSearchActive {
          Section {
            HomeStatsPanelView(
              driveCount: activeStatsPresenter.driveCount,
              distanceValue: activeStatsPresenter.distanceValue,
              distanceUnit: activeStatsPresenter.distanceUnit,
              scopeLabel: HomePresenter.statsScopeLabel(statsScope),
              onTap: { statsScope = statsScope == .last30Days ? .allTime : .last30Days }
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .popoverTip(StatsPanelTip())
          }
          .listSectionSpacing(8)
        }

        ForEach(sections) { section in
          Section(section.title) {
            ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
              if isSelectMode {
                Button {
                  toggleSelection(for: row.drive.id)
                } label: {
                  DriveRowView(drive: row.drive, display: row.display, style: .list(isSelected: selectedDriveIDs.contains(row.drive.id)))
                }
                .buttonStyle(.plain)
              } else {
                NavigationLink(value: row.drive) {
                  DriveRowView(drive: row.drive, display: row.display)
                }.accessibilityIdentifier("Drive row \(index)")
              }
            }
            .onDelete(perform: isSelectMode ? nil : { indexSet in
              deleteDrives(at: indexSet, in: section)
            })
          }
        }

        if isSelectMode {
          Color.clear
            .frame(height: 70)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
      }
      .contentMargins(.top, 0, for: .scrollContent)
      .navigationDestination(for: Drive.self) { drive in
        DriveDetailView(drive: drive, modelContainer: modelContext.container)
      }

      if isSelectMode {
        SelectionToolbar(
          canMerge: canMerge,
          canDelete: canDelete,
          selectionCountText: HomePresenter.selectionCountText(selectedDriveIDs.count)
        ) {
          triggerMerge()
        } onDelete: {
          showingDeleteConfirmation = true
        }
      }
    }
  }

  // MARK: - Actions

  private func startDrive(trigger: Drive.RecordingTrigger = .manual) {
    driveService.startDrive(trigger: trigger)
  }

  private func enterSelectMode() {
    isSelectMode = true
    selectedDriveIDs = []
  }

  private func exitSelectMode() {
    isSelectMode = false
    selectedDriveIDs = []
  }

  private func triggerMerge() {
    drivesToMerge = selectedDrives().sorted { $0.startedAt < $1.startedAt }
    showingMergeSheet = true
  }

  private func toggleSelection(for id: UUID) {
    if selectedDriveIDs.contains(id) {
      selectedDriveIDs.remove(id)
    } else {
      selectedDriveIDs.insert(id)
    }
  }

  private func selectedDrives() -> [Drive] {
    sections.flatMap(\.rows).map(\.drive).filter { selectedDriveIDs.contains($0.id) }
  }

  private func deleteDrives(_ drives: [Drive]) {
    DriveDeletion.delete(drives, in: modelContext, deindexing: spotlightIndexingService)
  }

  private func deleteDrives(at indexSet: IndexSet, in section: DriveSection) {
    deleteDrives(indexSet.map { section.rows[$0].drive })
  }

  private func mergeDrives(orderedDrives: [Drive], mergedName: String) {
    DriveMerge.merge(orderedDrives: orderedDrives, mergedName: mergedName, in: modelContext, deindexing: spotlightIndexingService)
  }

  private func openDrive(fromSpotlightIdentifier identifier: String) {
    guard let uuid = UUID(uuidString: identifier),
          let drive = drives.first(where: { $0.id == uuid }) else { return }
    navigationPath = NavigationPath()
    navigationPath.append(drive)
  }
}

// MARK: - HomeToolbar

private struct HomeToolbar: ToolbarContent {

  let isSelectMode: Bool
  let isSectionsEmpty: Bool
  let onExitSelectMode: () -> Void
  let onEnterSelectMode: () -> Void
  let onOpenSettings: () -> Void
  let onRecord: () -> Void

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      if isSelectMode {
        Button.cancel { onExitSelectMode() }
      }
    }

    if !isSelectMode {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button(
            String(localized: "Select Drives", comment: "Menu item to enter multiselect mode"),
            systemImage: "checkmark.circle"
          ) {
            onEnterSelectMode()
          }
          .disabled(isSectionsEmpty)

          Button(
            String(localized: "Settings", comment: "Menu item to open settings"),
            systemImage: "gear"
          ) {
            onOpenSettings()
          }
        } label: {
          Image(systemName: "ellipsis")
        }
        .accessibilityLabel(String(localized: "More options", comment: "Ellipsis menu accessibility label"))
      }

      DefaultToolbarItem(kind: .search, placement: .bottomBar)
      ToolbarSpacer(.fixed, placement: .bottomBar)

      ToolbarItem(placement: .bottomBar) {
        Button {
          onRecord()
        } label: {
          ZStack {
            Circle().fill(Color(.systemFill))
            Image(systemName: Icons.Selection.record)
              .font(.title2)
              .foregroundStyle(.red)
          }
          .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Start a new drive", comment: "Record button when idle"))
        .accessibilityIdentifier("NewDriveButton")
        .popoverTip(RecordButtonTip())
      }
    }
  }
}

// MARK: - RecordingScreenModifier

private struct RecordingScreenModifier: ViewModifier {

  @Environment(DriveRecordingService.self) private var driveService

  func body(content: Content) -> some View {
    content.fullScreenCover(isPresented: Binding(
      get: { driveService.isRecording },
      set: { _ in }
    )) {
      RecordingView()
    }
  }
}

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  PreviewSampleData.insertSampleDrives(in: container.mainContext)

  let locationService = LocationService()
  let locationDataRecorder = LocationDataRecorderService(locationService: locationService, modelContext: container.mainContext)
  let driveService = DriveRecordingService(modelContext: container.mainContext, locationService: locationService, locationDataRecorder: locationDataRecorder)

  return HomeView()
    .modelContainer(container)
    .environment(driveService)
    .environment(SpotlightIndexingService())
}
