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

  @Binding private var columnVisibility: NavigationSplitViewVisibility

  @State private var driveState: DriveDetailState
  @AppStorage("iPadInfoPanelVisible") private var isInspectorPresented: Bool = true
  @State private var showingDeleteConfirmation: Bool = false
  @State private var showingEditDrive: Bool = false
  @State private var showingMoreMenu: Bool = false

  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(drive: Drive, modelContainer: ModelContainer, columnVisibility: Binding<NavigationSplitViewVisibility>) {
    _driveState = State(initialValue: DriveDetailState(drive: drive, modelContainer: modelContainer))
    _columnVisibility = columnVisibility
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        Map(position: $driveState.cameraPosition, interactionModes: .all) {
          DriveMapContent(segments: driveState.coordinateSegments)
        }
        .mapStyle(.standard(emphasis: .muted))
        .ignoresSafeArea()
        .accessibilityLabel(Text(DriveDetailPresenter(drive: driveState.drive).routeAccessibilityLabel))
        .task { await driveState.loadRoute() }

        if isInspectorPresented {
          DriveBottomPanel(state: driveState, isPresented: $isInspectorPresented)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isInspectorPresented)
      .toolbar {
        DriveViewerToolbar(
          isInspectorPresented: $isInspectorPresented,
          showingMoreMenu: $showingMoreMenu,
          driveState: driveState
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
    .sheet(isPresented: $showingEditDrive) {
      EditDriveView(drive: driveState.drive)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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

// MARK: - DriveBottomPanel

private struct DriveBottomPanel: View {

  // MARK: - Properties

  let state: DriveDetailState
  @Binding var isPresented: Bool

  @AppStorage("iPadInfoPanelDetent") private var detent: Detent = .medium
  @State private var currentHeight: CGFloat = 0
  @State private var dragStartHeight: CGFloat = 0
  @State private var isDragging = false

  private enum Detent: String { case collapsed, medium, expanded }

  // MARK: - Body

  var body: some View {
    GeometryReader { geo in
      let availableHeight = geo.size.height
      let displayHeight = max(60, currentHeight > 0 ? currentHeight : targetHeight(for: detent, in: availableHeight))

      VStack(spacing: 0) {
        handle(availableHeight: availableHeight)
        DriveInfoPanel(state: state)
      }
      .frame(maxWidth: .infinity)
      .frame(height: displayHeight, alignment: .top)
      .background(.ultraThinMaterial, in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20, style: .continuous))
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      .onAppear {
        if currentHeight == 0 {
          currentHeight = targetHeight(for: detent, in: availableHeight)
        }
      }
    }
  }

  // MARK: - Private

  private func targetHeight(for detent: Detent, in availableHeight: CGFloat) -> CGFloat {
    switch detent {
    case .collapsed: return 80
    case .medium: return availableHeight * 0.45
    case .expanded: return availableHeight * 0.88
    }
  }

  private func nearestDetent(for height: CGFloat, in availableHeight: CGFloat) -> Detent {
    let options: [(Detent, CGFloat)] = [
      (.collapsed, targetHeight(for: .collapsed, in: availableHeight)),
      (.medium, targetHeight(for: .medium, in: availableHeight)),
      (.expanded, targetHeight(for: .expanded, in: availableHeight))
    ]
    return options.min(by: { abs($0.1 - height) < abs($1.1 - height) })?.0 ?? .medium
  }

  private func handle(availableHeight: CGFloat) -> some View {
    Capsule()
      .fill(Color.secondary.opacity(0.5))
      .frame(width: 36, height: 5)
      .padding(.vertical, 8)
      .frame(maxWidth: .infinity)
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 5)
          .onChanged { value in
            if !isDragging {
              isDragging = true
              dragStartHeight = currentHeight
            }
            currentHeight = max(60, dragStartHeight - value.translation.height)
          }
          .onEnded { value in
            isDragging = false
            let predictedTranslation = value.predictedEndTranslation.height
            if detent == .collapsed && predictedTranslation > 120 {
              withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isPresented = false
              }
              return
            }
            let predictedHeight = max(60, dragStartHeight - predictedTranslation)
            let newDetent = nearestDetent(for: predictedHeight, in: availableHeight)
            detent = newDetent
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
              currentHeight = targetHeight(for: newDetent, in: availableHeight)
            }
          }
      )
  }
}

// MARK: - DriveViewerToolbar

private struct DriveViewerToolbar: ToolbarContent {

  @Binding var isInspectorPresented: Bool
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
        isInspectorPresented.toggle()
      } label: {
        Image(systemName: "info.circle")
      }
      .accessibilityLabel(String(localized: "Toggle drive info panel", comment: "Info panel toggle button accessibility label"))
    }
  }
}
