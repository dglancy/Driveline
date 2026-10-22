//
//  HomeView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import CoreSpotlight
import SwiftUI
import SwiftData
import TipKit

struct HomeView: View {

  // MARK: - Properties

  @Environment(DriveRecordingService.self) private var driveService
  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(LocationService.self) private var locationService
  @Environment(\.modelContext) private var modelContext
  @Environment(\.openURL) private var openURL

  @Query(sort: \Drive.startedAt, order: .reverse)
  private var drives: [Drive]

  @State private var selectedDriveID: UUID?
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
  @State private var searchText: String = ""
  @State private var statsScope: StatsScope = .last30Days
  @State private var isSelectMode: Bool = false
  @State private var selectedDriveIDs: Set<UUID> = []
  @State private var mergeSelection: MergeSelection?
  @State private var showingDeleteConfirmation: Bool = false
  @State private var showingLocationPrimer: Bool = false
  @State private var showingAutomationSetup: Bool = false
  @State private var hasSeenAutomationSetup: Bool = UserPreferences().hasSeenAutomationSetup

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
  private var selectedDrive: Drive? { drives.first { $0.id == selectedDriveID } }

  // MARK: - Body

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
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
            onOpenSettings: openSettings,
            onRecord: attemptManualRecord
          )
        }
        .onChange(of: driveService.isRecording, initial: true, updateRecordingTips)
        .onChange(of: recentStats.driveCount, initial: true, updateStatsTip)
        .onChange(of: drives.isEmpty, initial: true, updateRecordButtonTip)
        .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 480)
    } detail: {
      detail
    }
      .navigationSplitViewStyle(.balanced)
      .onContinueUserActivity(CSSearchableItemActionType, perform: handleSpotlightActivity)
      .modifier(RecordingScreenModifier())
      .modifier(LocationPrimerModifier(
        isPresented: $showingLocationPrimer,
        onStartDrive: { startDrive() }
      ))
      .modifier(AutomationSetupModifier(
        isPresented: $showingAutomationSetup,
        hasSeenAutomationSetup: $hasSeenAutomationSetup
      ))
      .alert(
        String(localized: "Delete Drives", comment: "Delete confirmation alert title"),
        isPresented: $showingDeleteConfirmation,
        actions: deleteConfirmationActions,
        message: deleteConfirmationMessage
      )
      .sheet(item: $mergeSelection, content: mergeSheet)
  }

  // MARK: - Private Views

  private var detail: some View {
    NavigationStack {
      if let selectedDrive {
        DriveDetailView(
          drive: selectedDrive,
          modelContainer: modelContext.container,
          onClose: closeSelectedDrive
        )
        .id(selectedDrive.id)
      } else {
        HomeDetailPlaceholderView()
      }
    }
  }

  @ViewBuilder
  private func deleteConfirmationActions() -> some View {
      Button.delete {
        deleteSelectedDrives()
      }
      Button.cancel()
  }

  private func deleteConfirmationMessage() -> some View {
    Text(HomePresenter.deleteConfirmationMessage(selectedDriveIDs.count))
  }

  private func mergeSheet(selection: MergeSelection) -> some View {
    MergeDrivesView(
      drives: selection.drives,
      modelContainer: modelContext.container,
      spotlight: spotlightIndexingService,
      onMerged: exitSelectMode
    )
  }

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
    ContentUnavailableView {
      Label("No Drives", systemImage: Icons.Widgets.car)
    } description: {
      Text(String(localized: "Your recorded drives will appear here.", comment: "Empty state description shown on the home screen when no drives have been recorded yet"))
    } actions: {
      Button(HomePresenter.newDriveButtonTitle) {
        attemptManualRecord()
      }
      .buttonStyle(.borderedProminent)
    }
  }

  private var driveList: some View {
    List(selection: $selectedDriveID) {
      if !drives.isEmpty && !isSelectMode && !isSearchActive {
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

      if !hasSeenAutomationSetup && !isSelectMode && !isSearchActive
          && (!Driveline.isUITesting() || Driveline.isOnboardingTesting()) {
        Section {
          HomeAutomationSetupPanelView { showingAutomationSetup = true }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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
              .accessibilityIdentifier("Drive row \(index)")
            } else {
              NavigationLink(value: row.drive.id) {
                DriveRowView(drive: row.drive, display: row.display)
              }.accessibilityIdentifier("Drive row \(index)")
            }
          }
          .onDelete(perform: isSelectMode ? nil : { indexSet in
            deleteDrives(at: indexSet, in: section)
          })
        }
      }

    }
    .contentMargins(.top, 0, for: .scrollContent)
    .safeAreaInset(edge: .bottom, spacing: 0) {
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

  private func updateRecordingTips(_ oldValue: Bool, _ isRecording: Bool) {
    if isRecording { exitSelectMode() }
    StatsPanelTip.isRecording = isRecording
    RecordButtonTip.isRecording = isRecording
  }

  private func updateStatsTip(_ oldValue: Int, _ driveCount: Int) {
    StatsPanelTip.driveCount = driveCount
  }

  private func updateRecordButtonTip(_ oldValue: Bool, _ isEmpty: Bool) {
    RecordButtonTip.hasDrives = !isEmpty
  }

  private func handleSpotlightActivity(_ activity: NSUserActivity) {
    guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
    openDrive(fromSpotlightIdentifier: identifier)
  }

  private func openSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    openURL(url)
  }

  private func attemptManualRecord() {
    guard !Driveline.isUITesting() else {
      startDrive()
      return
    }
    if locationService.authorizationStatus == .authorizedAlways {
      startDrive()
    } else {
      showingLocationPrimer = true
    }
  }

  private func startDrive(trigger: Drive.RecordingTrigger = .manual) {
    driveService.startDrive(trigger: trigger)
  }

  private func enterSelectMode() {
    closeSelectedDrive()
    isSelectMode = true
    selectedDriveIDs = []
  }

  private func exitSelectMode() {
    isSelectMode = false
    selectedDriveIDs = []
  }

  private func triggerMerge() {
    let selectedDrives = selectedDrives().sorted { $0.startedAt < $1.startedAt }
    guard selectedDrives.count == 2 else { return }
    mergeSelection = MergeSelection(drives: selectedDrives)
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

  private func deleteSelectedDrives() {
    let selected = selectedDrives()
    exitSelectMode()
    deleteDrives(selected)
  }

  private func deleteDrives(at indexSet: IndexSet, in section: DriveSection) {
    deleteDrives(indexSet.map { section.rows[$0].drive })
  }

  private func openDrive(fromSpotlightIdentifier identifier: String) {
    guard let uuid = UUID(uuidString: identifier),
          let drive = drives.first(where: { $0.id == uuid }) else { return }
    selectedDriveID = drive.id
    preferredCompactColumn = .detail
  }

  private func closeSelectedDrive() {
    selectedDriveID = nil
    preferredCompactColumn = .sidebar
  }
}

// MARK: - HomeDetailPlaceholderView

private struct HomeDetailPlaceholderView: View {

  var body: some View {
    ContentUnavailableView {
      Label("Select a Drive", systemImage: Icons.Widgets.car)
    } description: {
      Text("Choose a drive to view its route and details.")
    }
    .accessibilityIdentifier("HomeDriveDetailPlaceholder")
  }
}

// MARK: - MergeSelection

private struct MergeSelection: Identifiable {

  // MARK: - Properties

  let id = UUID()
  let drives: [Drive]
}

// MARK: - HomeToolbar

private struct HomeToolbar: ToolbarContent {

  // MARK: - Properties

  let isSelectMode: Bool
  let isSectionsEmpty: Bool
  let onExitSelectMode: () -> Void
  let onEnterSelectMode: () -> Void
  let onOpenSettings: () -> Void
  let onRecord: () -> Void

  // MARK: - Body

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      if isSelectMode {
        Button.cancel { onExitSelectMode() }
      }
    }

    if !isSelectMode {
      ToolbarItem(placement: .topBarPinnedTrailing) {
        Button {
          onRecord()
        } label: {
          Image(systemName: Icons.Selection.record)
            .foregroundStyle(.red)
        }
        .accessibilityLabel(String(localized: "Start a new drive", comment: "Record button when idle"))
        .accessibilityIdentifier("NewDriveButton")
        .popoverTip(RecordButtonTip())
      }
      .visibilityPriority(.high)

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
    }
  }
}

// MARK: - RecordingScreenModifier

private struct RecordingScreenModifier: ViewModifier {

  // MARK: - Properties

  @Environment(DriveRecordingService.self) private var driveService

  // MARK: - Body

  func body(content: Content) -> some View {
    content.fullScreenCover(isPresented: Binding(
      get: { driveService.isRecording },
      set: { _ in }
    )) {
      RecordingView()
    }
  }
}

// MARK: - LocationPrimerModifier

private struct LocationPrimerModifier: ViewModifier {

  // MARK: - Properties

  @Environment(LocationService.self) private var locationService
  @Binding var isPresented: Bool
  let onStartDrive: () -> Void

  // MARK: - Body

  func body(content: Content) -> some View {
    content.fullScreenCover(isPresented: $isPresented) {
      LocationPermissionFlowView(
        initialStatus: locationService.authorizationStatus,
        onComplete: {
          isPresented = false
          onStartDrive()
        },
        onDismiss: { isPresented = false }
      )
      .environment(locationService)
    }
  }
}

// MARK: - AutomationSetupModifier

private struct AutomationSetupModifier: ViewModifier {

  // MARK: - Properties

  @Binding var isPresented: Bool
  @Binding var hasSeenAutomationSetup: Bool

  // MARK: - Body

  func body(content: Content) -> some View {
    content.fullScreenCover(isPresented: $isPresented) {
      AutomationSetupFlowView(
        onComplete: {
          var prefs = UserPreferences()
          prefs.setHasSeenAutomationSetup(true)
          hasSeenAutomationSetup = true
          isPresented = false
        }
      )
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
    .environment(locationService)
    .environment(SpotlightIndexingService())
}
