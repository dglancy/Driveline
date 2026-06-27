//
//  DriveViewerView.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import MapKit
import SwiftData
import SwiftUI

struct DriveViewerView: View {

  // MARK: - Properties

  @State private var driveState: DriveDetailState
  @State private var isInspectorPresented: Bool = true
  @State private var showingFullScreenMap: Bool = false
  @State private var showingDeleteConfirmation: Bool = false
  @State private var showingEditDrive: Bool = false
  @State private var showingMoreMenu: Bool = false

  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(drive: Drive, modelContainer: ModelContainer) {
    _driveState = State(initialValue: DriveDetailState(drive: drive, modelContainer: modelContainer))
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Map(position: $driveState.cameraPosition, interactionModes: .all) {
        DriveMapContent(segments: driveState.coordinateSegments)
      }
      .mapStyle(.standard(emphasis: .muted))
      .ignoresSafeArea()
      .accessibilityLabel(Text(DriveDetailPresenter(drive: driveState.drive).routeAccessibilityLabel))
      .task { await driveState.loadRoute() }
      .toolbar {
        DriveViewerToolbar(
          isInspectorPresented: $isInspectorPresented,
          showingFullScreenMap: $showingFullScreenMap,
          showingMoreMenu: $showingMoreMenu,
          driveState: driveState
        )
      }
      .inspector(isPresented: $isInspectorPresented) {
        DriveInfoPanel(state: driveState)
      }
      .navigationDestination(isPresented: $showingFullScreenMap) {
        FullScreenMapView(
          drive: driveState.drive,
          modelContainer: driveState.drive.modelContext?.container ?? modelContext.container
        )
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

// MARK: - DriveViewerToolbar

private struct DriveViewerToolbar: ToolbarContent {

  @Binding var isInspectorPresented: Bool
  @Binding var showingFullScreenMap: Bool
  @Binding var showingMoreMenu: Bool
  let driveState: DriveDetailState

  var body: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Menu {
        Button {
          Task { await driveState.share(.gpx) }
        } label: {
          Label(String(localized: "Share as GPX", comment: "Share drive as GPX"), systemImage: Icons.Options.gpxFile)
        }
        Button {
          Task { await driveState.share(.png) }
        } label: {
          Label(String(localized: "Share as PNG", comment: "Share drive as PNG"), systemImage: Icons.Options.pngImage)
        }
      } label: {
        Image(systemName: Icons.Options.sharing)
      }
      .accessibilityLabel(String(localized: "Share Drive", comment: "Share button accessibility label"))
    }

    ToolbarItem(placement: .topBarTrailing) {
      Button {
        showingMoreMenu = true
      } label: {
        Image(systemName: Icons.Options.ellipsis)
      }
      .accessibilityLabel(String(localized: "More options", comment: "More options button accessibility label"))
    }

    ToolbarItem(placement: .topBarTrailing) {
      Button {
        showingFullScreenMap = true
      } label: {
        Image(systemName: Icons.Options.viewfinder)
      }
      .accessibilityLabel(String(localized: "Full screen map", comment: "Full screen map button accessibility label"))
    }

    ToolbarItem(placement: .topBarTrailing) {
      Button {
        isInspectorPresented.toggle()
      } label: {
        Image(systemName: "sidebar.right")
      }
      .accessibilityLabel(String(localized: "Toggle drive info panel", comment: "Inspector toggle button accessibility label"))
    }
  }
}
