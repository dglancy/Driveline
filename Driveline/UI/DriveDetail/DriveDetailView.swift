//
//  DriveDetailView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftData
import SwiftUI
import TipKit

struct DriveDetailView: View {

  // MARK: - Properties

  @State private var driveState: DriveDetailState
  @State private var showingFullScreenMap = false
  @State private var showingMoreMenu = false
  @State private var showingDeleteConfirmation = false
  @State private var showingEditDrive = false

  private let renameDriveTip = EditDriveTip()

  @Environment(\.dismiss) private var dismiss
  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(\.modelContext) private var modelContext

  private let mapHeight: CGFloat = 280

  // MARK: - Lifecycle

  init(drive: Drive, modelContainer: ModelContainer) {
    _driveState = State(initialValue: DriveDetailState(drive: drive, modelContainer: modelContainer))
  }

  // MARK: - Body

  var body: some View {
    let presenter = DriveDetailPresenter(drive: driveState.drive)
    ZStack(alignment: .top) {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        DriveDetailMapView(segments: driveState.coordinateSegments, cameraPosition: $driveState.cameraPosition, accessibilityLabel: presenter.routeAccessibilityLabel)
          .frame(height: mapHeight)
          .task { await driveState.loadRoute() }
          .overlay(alignment: .topLeading) {
            GlassButton(systemImage: Icons.Navigation.chevronLeft, accessibilityLabel: LocalizedStringResource("Back", comment: "Accessibility label for the back button on the drive detail screen")) { dismiss() }
              .padding(14)
          }
          .overlay(alignment: .topTrailing) {
            GlassButton(systemImage: Icons.Options.ellipsis, accessibilityLabel: LocalizedStringResource("More options", comment: "Accessibility label for the more options button on the drive detail screen")) {
              renameDriveTip.invalidate(reason: .actionPerformed)
              showingMoreMenu = true
            }
            .padding(14)
            .popoverTip(renameDriveTip)
          }
          .overlay(alignment: .bottomTrailing) {
            GlassButton(systemImage: Icons.Options.viewfinder, accessibilityLabel: LocalizedStringResource("Full screen map", comment: "Accessibility label for the button that opens the full screen map on the drive detail screen")) {
              showingFullScreenMap = true
            }
            .padding(14)
          }

        DriveInfoPanel(state: driveState)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .navigationDestination(isPresented: $showingFullScreenMap) {
      FullScreenMapView(drive: driveState.drive, modelContainer: driveState.drive.modelContext?.container ?? modelContext.container)
    }
    .alert(
      String(localized: "Delete Drive", comment: "Delete confirmation alert title"),
      isPresented: $showingDeleteConfirmation
    ) {
      Button.delete {
        DriveDeletion.delete([driveState.drive], in: modelContext, deindexing: spotlightIndexingService)
        dismiss()
      }
      Button.cancel()
    } message: {
      Text(String(localized: "This drive and all its data will be permanently deleted.", comment: "Delete drive confirmation message"))
    }
    .sheet(isPresented: $showingEditDrive) {
      EditDriveView(drive: driveState.drive)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .confirmationDialog(
      String(localized: "Drive Options", comment: "More menu title"),
      isPresented: $showingMoreMenu
    ) {
      Button(String(localized: "Edit Drive Details", comment: "More menu action")) {
        showingEditDrive = true
      }
      Button(String(localized: "Delete Drive", comment: "More menu action"), role: .destructive) {
        showingDeleteConfirmation = true
      }
      Button.cancel()
    }
    .sheet(item: $driveState.shareItem) { item in
      ActivityView(activityItems: [item.url])
    }
    .alert(
      String(localized: "Couldn't Share Drive", comment: "Export failure alert title"),
      isPresented: $driveState.showingExportError
    ) {
      Button(String(localized: "OK", comment: "Dismiss export error alert"), role: .cancel) { }
    } message: {
      Text(driveState.exportErrorMessage ?? "")
    }
  }

}

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  let drive = PreviewSampleData.sampleDrive(in: container.mainContext)
  return NavigationStack {
    DriveDetailView(drive: drive, modelContainer: container)
  }
  .modelContainer(container)
  .environment(SpotlightIndexingService())
}
