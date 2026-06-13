//
//  HomeView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreSpotlight
import SwiftUI
import SwiftData

struct HomeView: View {

  // MARK: - Properties

  @Environment(DriveRecordingService.self) private var driveService
  @Environment(\.openURL) private var openURL

  @Query(sort: \Drive.startedAt, order: .reverse) private var drives: [Drive]

  private let modelContext: ModelContext
  private let spotlightIndexingService: SpotlightIndexingService
  @State private var viewModel: HomeViewModel

  // MARK: - Lifecycle

  init(spotlightIndexingService: SpotlightIndexingService, modelContext: ModelContext) {
    self.spotlightIndexingService = spotlightIndexingService
    self.modelContext = modelContext
    _viewModel = State(initialValue: HomeViewModel(spotlightIndexingService: spotlightIndexingService, modelContext: modelContext))
  }

  // MARK: - Body

  var body: some View {
    @Bindable var viewModel = viewModel
    NavigationStack(path: $viewModel.navigationPath) {
      content
        .navigationTitle("Drives")
        .searchable(text: $viewModel.searchText, prompt: "Search")
        .searchDictationBehavior(.inline(activation: .onSelect))
        .searchToolbarBehavior(.minimize)
        .toolbar { toolbarItems }
        .onChange(of: drives, initial: true) { _, newDrives in
          viewModel.update(with: newDrives)
        }
        .onChange(of: driveService.isRecording) { _, isRecording in
          if isRecording {
            viewModel.exitSelectMode()
          }
        }
    }
    .onContinueUserActivity(CSSearchableItemActionType) { activity in
      guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
      viewModel.openDrive(fromSpotlightIdentifier: identifier)
    }
    .modifier(RecordingScreenModifier(driveService: driveService))
    .modifier(DeleteDrivesAlertModifier(viewModel: viewModel, isPresented: $viewModel.showingDeleteConfirmation))
    .modifier(StartDriveErrorAlertModifier(viewModel: viewModel, isPresented: $viewModel.showingStartDriveError))
    .modifier(MergeDrivesSheetModifier(viewModel: viewModel, isPresented: $viewModel.showingMergeSheet))
  }

  // MARK: - Private Views

  @ViewBuilder
  private var content: some View {
    if viewModel.sections.isEmpty {
      if !viewModel.isSearchActive {
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
        if viewModel.recentStats.driveCount > 0 && !viewModel.isSelectMode && !viewModel.isSearchActive {
          Section {
            HomeStatsPanelView(
              driveCount: viewModel.statsDriveCount,
              distanceValue: viewModel.statsDistanceValue,
              distanceUnit: viewModel.statsDistanceUnit,
              scopeLabel: viewModel.statsScopeLabel,
              onTap: viewModel.toggleStatsScope
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          }
          .listSectionSpacing(8)
        }

        ForEach(viewModel.sections) { section in
          Section(section.title) {
            ForEach(section.rows) { row in
              if viewModel.isSelectMode {
                Button {
                  viewModel.toggleSelection(for: row.drive.id)
                } label: {
                  DriveRowView(drive: row.drive, display: row.display, style: .list(isSelected: viewModel.selectedDriveIDs.contains(row.drive.id)))
                }
                .buttonStyle(.plain)
              } else {
                NavigationLink(value: row.drive) {
                  DriveRowView(drive: row.drive, display: row.display)
                }
              }
            }
            .onDelete(perform: viewModel.isSelectMode ? nil : { indexSet in
              viewModel.deleteDrives(at: indexSet, in: section)
            })
          }
        }

        if viewModel.isSelectMode {
          Color.clear
            .frame(height: 70)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
      }
      .contentMargins(.top, 0, for: .scrollContent)
      .navigationDestination(for: Drive.self) { drive in
        DriveDetailView(drive: drive, spotlightIndexingService: spotlightIndexingService, modelContext: modelContext)
      }

      if viewModel.isSelectMode {
        SelectionToolbar(
          canMerge: viewModel.canMerge,
          canDelete: viewModel.canDelete,
          selectionCountText: viewModel.selectionCountText
        ) {
          viewModel.triggerMerge()
        } onDelete: {
          viewModel.showingDeleteConfirmation = true
        }
      }
    }
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var toolbarItems: some ToolbarContent {
    cancelToolbarItem

    if !viewModel.isSelectMode {
      overflowMenuItem
      recordButtonItem
    }
  }

  @ToolbarContentBuilder
  private var cancelToolbarItem: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      if viewModel.isSelectMode {
        Button.cancel { viewModel.exitSelectMode() }
      }
    }
  }

  @ToolbarContentBuilder
  private var overflowMenuItem: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Menu {
        Button(
          String(localized: "Select Drives", comment: "Menu item to enter multiselect mode"),
          systemImage: "checkmark.circle"
        ) {
          viewModel.enterSelectMode()
        }
        .disabled(viewModel.sections.isEmpty)

        Button(
          String(localized: "Settings", comment: "Menu item to open settings"),
          systemImage: "gear"
        ) {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
          }
        }
      } label: {
        Image(systemName: "ellipsis")
      }
      .accessibilityLabel(String(localized: "More options", comment: "Ellipsis menu accessibility label"))
    }
  }

  @ToolbarContentBuilder
  private var recordButtonItem: some ToolbarContent {
    ToolbarItem(placement: .bottomBar) {
      Button {
        viewModel.startDrive(using: driveService)
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
    }
  }
}

// MARK: - Presentation Modifiers

private struct RecordingScreenModifier: ViewModifier {
  let driveService: DriveRecordingService

  func body(content: Content) -> some View {
    content.fullScreenCover(isPresented: Binding(
      get: { driveService.isRecording },
      set: { _ in }
    )) {
      NavigationStack {
        RecordingView(driveService: driveService)
          .toolbarVisibility(.hidden, for: .navigationBar)
      }
    }
  }
}

private struct DeleteDrivesAlertModifier: ViewModifier {
  let viewModel: HomeViewModel
  var isPresented: Binding<Bool>

  func body(content: Content) -> some View {
    content.alert(
      String(localized: "Delete Drives", comment: "Delete confirmation alert title"),
      isPresented: isPresented
    ) {
      Button.delete {
        let selected = viewModel.selectedDrives(from: viewModel.sections)
        viewModel.exitSelectMode()
        viewModel.deleteDrives(selected)
      }
      Button.cancel()
    } message: {
      Text(viewModel.deleteConfirmationMessage)
    }
  }
}

private struct StartDriveErrorAlertModifier: ViewModifier {
  let viewModel: HomeViewModel
  var isPresented: Binding<Bool>

  func body(content: Content) -> some View {
    content.alert(
      String(localized: "Couldn't Start Recording", comment: "Start drive failure alert title"),
      isPresented: isPresented
    ) {
      Button(String(localized: "OK", comment: "Dismiss start drive error alert"), role: .cancel) { }
    } message: {
      Text(viewModel.startDriveErrorMessage ?? "")
    }
  }
}

private struct MergeDrivesSheetModifier: ViewModifier {
  let viewModel: HomeViewModel
  var isPresented: Binding<Bool>

  func body(content: Content) -> some View {
    content.sheet(isPresented: isPresented) {
      if viewModel.drivesToMerge.count == 2 {
        MergeDrivesView(drives: viewModel.drivesToMerge) { orderedDrives, mergedName in
          viewModel.mergeDrives(orderedDrives: orderedDrives, mergedName: mergedName)
        }
      }
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

  return HomeView(spotlightIndexingService: SpotlightIndexingService(), modelContext: container.mainContext)
    .modelContainer(container)
    .environment(driveService)
}
