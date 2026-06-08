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

  @Environment(\.modelContext) private var modelContext
  @Environment(DriveRecordingService.self) private var driveService
  @Environment(\.spotlightIndexingService) private var spotlightIndexingService

  @Query(sort: \Drive.startedAt, order: .reverse) private var drives: [Drive]

  @State private var viewModel = HomeViewModel()

  // MARK: - Body

  var body: some View {
    @Bindable var viewModel = viewModel
    NavigationStack(path: $viewModel.navigationPath) {
      content
        .navigationTitle("Drives")
        .toolbar { toolbarItems }
        .onChange(of: drives, initial: true) { _, newDrives in
          viewModel.update(with: newDrives)
        }
        .onChange(of: driveService.isRecording) { _, isRecording in
          if isRecording {
            viewModel.exitSelectMode()
          } else {
            viewModel.update(with: drives)
          }
          viewModel.showingRecordingScreen = isRecording
        }
        .onAppear {
          viewModel.modelContext = modelContext
          viewModel.spotlightIndexingService = spotlightIndexingService
          viewModel.showingRecordingScreen = driveService.isRecording
        }
    }
    .onContinueUserActivity(CSSearchableItemActionType) { activity in
      guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let uuid = UUID(uuidString: identifier),
            let drive = drives.first(where: { $0.id == uuid }) else { return }
      viewModel.navigationPath = NavigationPath()
      viewModel.navigationPath.append(drive)
    }
    .modifier(RecordingScreenModifier(driveService: driveService, isPresented: $viewModel.showingRecordingScreen))
    .modifier(DeleteDrivesAlertModifier(viewModel: viewModel, isPresented: $viewModel.showingDeleteConfirmation))
    .modifier(StartDriveErrorAlertModifier(viewModel: viewModel, isPresented: $viewModel.showingStartDriveError))
    .modifier(MergeDrivesSheetModifier(viewModel: viewModel, isPresented: $viewModel.showingMergeSheet))
  }

  // MARK: - Private Views

  @ViewBuilder
  private var content: some View {
    if viewModel.sections.isEmpty && !driveService.isRecording {
      emptyState
    } else {
      driveList
    }
  }

  private var emptyState: some View {
    ContentUnavailableView(
      "No Drives",
      systemImage: Icons.car,
      description: Text(String(localized: "Your recorded drives will appear here.", comment: "Empty state description shown on the home screen when no drives have been recorded yet"))
    )
  }

  private var driveList: some View {
    ZStack(alignment: .bottom) {
      List {
        if driveService.isRecording {
          RecordingBannerSection {
            viewModel.showingRecordingScreen = true
          }
        }

        if let summary = viewModel.summaryLine {
          Section {
            Text(summary)
              .font(.callout)
              .foregroundStyle(.secondary)
              .listRowBackground(Color.clear)
              .frame(maxWidth: .infinity, alignment: .center)
              .dynamicTypeSize(.large ... .xxLarge)
          }
          .listSectionSpacing(0)
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
                    .opacity(driveService.isRecording ? 0.4 : 1)
                }
                .disabled(driveService.isRecording)
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
        DriveDetailView(drive: drive)
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
    ToolbarItem(placement: .topBarLeading) {
      if viewModel.isSelectMode {
        Button.cancel { viewModel.exitSelectMode() }
      } else if !viewModel.sections.isEmpty {
        Button(String(localized: "Select", comment: "Enter multiselect mode")) {
          viewModel.enterSelectMode()
        }
        .disabled(driveService.isRecording)
      }
    }

    ToolbarItem(placement: .topBarTrailing) {
      if !viewModel.isSelectMode {
        Button {
          if driveService.isRecording {
            viewModel.showingRecordingScreen = true
          } else {
            viewModel.startDrive(using: driveService)
          }
        } label: {
          ZStack {
            Circle().fill(Color(.systemFill))
            if driveService.isRecording {
              RoundedRectangle(cornerRadius: 3)
                .fill(.red)
                .frame(width: 11, height: 11)
            } else {
              Image(systemName: Icons.recordingActive)
                .font(.title2)
                .foregroundStyle(.red)
            }
          }
          .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
          driveService.isRecording
          ? String(localized: "Currently recording — open recording screen", comment: "Record button when recording")
          : String(localized: "Start a new drive", comment: "Record button when idle")
        )
      }
    }
  }
}

// MARK: - Presentation Modifiers

private struct RecordingScreenModifier: ViewModifier {
  let driveService: DriveRecordingService
  var isPresented: Binding<Bool>

  func body(content: Content) -> some View {
    content.fullScreenCover(isPresented: isPresented) {
      RecordingView(driveService: driveService)
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

  return HomeView()
    .modelContainer(container)
    .environment(driveService)
}
