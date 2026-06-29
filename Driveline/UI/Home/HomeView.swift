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

  @State private var navigationPath: NavigationPath = NavigationPath()
  @State private var searchText: String = ""
  @State private var statsScope: StatsScope = .last30Days
  @State private var managementState = DriveManagementState()
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

  // MARK: - Body

  var body: some View {
    NavigationStack(path: $navigationPath) {
      content
        .navigationTitle("Drives")
        .searchable(text: $searchText, prompt: "Search")
        .searchDictationBehavior(.inline(activation: .onSelect))
        .toolbar {
          HomeToolbar(
            isSelectMode: managementState.isSelectMode,
            isSectionsEmpty: sections.isEmpty,
            onExitSelectMode: { managementState.exitSelectMode() },
            onEnterSelectMode: { managementState.enterSelectMode() },
            onOpenSettings: {
              if let url = URL(string: UIApplication.openSettingsURLString) {
                openURL(url)
              }
            },
            onRecord: { attemptManualRecord() }
          )
        }
        .onChange(of: driveService.isRecording, initial: true) { _, isRecording in
          if isRecording { managementState.exitSelectMode() }
          StatsPanelTip.isRecording = isRecording
          RecordButtonTip.isRecording = isRecording
        }
        .onChange(of: recentStats.driveCount, initial: true) { _, count in
          StatsPanelTip.driveCount = count
        }
        .onChange(of: drives.isEmpty, initial: true) { _, isEmpty in
          RecordButtonTip.hasDrives = !isEmpty
        }
    }
    .onContinueUserActivity(CSSearchableItemActionType) { activity in
      guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
      openDrive(fromSpotlightIdentifier: identifier)
    }
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
      isPresented: $managementState.showingDeleteConfirmation
    ) {
      Button.delete {
        let selected = managementState.selectedDrives(from: sections)
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
    ZStack(alignment: .bottom) {
      DriveListContent(
        sections: sections,
        managementState: managementState,
        mode: .pushNavigation,
        recentDriveCount: recentStats.driveCount,
        activeStatsPresenter: activeStatsPresenter,
        statsScopeLabel: HomePresenter.statsScopeLabel(statsScope),
        isSearchActive: isSearchActive,
        onStatsToggle: { statsScope = statsScope == .last30Days ? .allTime : .last30Days },
        showAutomationBanner: !hasSeenAutomationSetup && (!Driveline.isUITesting() || Driveline.isOnboardingTesting()),
        onShowAutomation: { showingAutomationSetup = true }
      )
      .navigationDestination(for: Drive.self) { drive in
        DriveDetailView(drive: drive, modelContainer: modelContext.container)
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
  }

  // MARK: - Actions

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

// MARK: - LocationPrimerModifier

private struct LocationPrimerModifier: ViewModifier {

  @Environment(LocationService.self) private var locationService
  @Binding var isPresented: Bool
  let onStartDrive: () -> Void

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

  @Binding var isPresented: Bool
  @Binding var hasSeenAutomationSetup: Bool

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
