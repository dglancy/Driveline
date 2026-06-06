//
//  DriveDetailView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import MapKit
import SwiftData
import SwiftUI

struct DriveDetailView: View {

  // MARK: - Properties

  @State private var viewModel: DriveDetailViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  private let mapHeight: CGFloat = 280

  // MARK: - Lifecycle

  init(drive: Drive) {
    _viewModel = State(initialValue: DriveDetailViewModel(drive: drive))
  }

  // MARK: - Body

  var body: some View {
    ZStack(alignment: .top) {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        DriveDetailMapView(coordinates: viewModel.coordinates, cameraPosition: viewModel.cameraPosition)
          .frame(height: mapHeight)
          .overlay(alignment: .topLeading) {
            GlassButton(systemImage: Icons.chevronLeft, accessibilityLabel: LocalizedStringResource("Back", comment: "Accessibility label for the back button on the drive detail screen")) { dismiss() }
              .padding(14)
          }
          .overlay(alignment: .topTrailing) {
            GlassButton(systemImage: Icons.ellipsis, accessibilityLabel: LocalizedStringResource("More options", comment: "Accessibility label for the more options button on the drive detail screen")) {
              viewModel.showingMoreMenu = true
            }
            .padding(14)
          }
          .overlay(alignment: .bottomTrailing) {
            GlassButton(systemImage: Icons.viewfinder, accessibilityLabel: LocalizedStringResource("Full screen map", comment: "Accessibility label for the button that opens the full screen map on the drive detail screen")) {
              viewModel.showingFullScreenMap = true
            }
            .padding(14)
          }

        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            driveHeader
            statTiles
            endpointsCard
            metadataCard
            shareDriveButton
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 24)
        }
        .padding(.top, 20)
        .contentMargins(.top, 0, for: .scrollContent)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .onAppear { viewModel.modelContext = modelContext }
    .modifier(FullScreenMapModifier(viewModel: viewModel))
    .modifier(ExportShareSheetModifier(viewModel: viewModel))
    .modifier(ExportErrorAlertModifier(viewModel: viewModel))
    .modifier(DeleteDriveAlertModifier(viewModel: viewModel, dismiss: { dismiss() }))
    .modifier(EditDriveSheetModifier(viewModel: viewModel))
    .modifier(DriveOptionsDialogModifier(viewModel: viewModel))
    .modifier(ShareDriveDialogModifier(viewModel: viewModel))
  }

  // MARK: - Private Views

  private var driveHeader: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(viewModel.name)
        .font(.title.weight(.bold))
        .foregroundStyle(Color(.label))
        .dynamicTypeSize(.xSmall ... .accessibility1)
      Text(viewModel.dateString)
        .font(.callout)
        .foregroundStyle(.secondary)
        .dynamicTypeSize(.xSmall ... .accessibility1)
    }
  }

  private var statTiles: some View {
    HStack(spacing: 10) {
      DriveStatTile(
        icon: "ruler",
        label: String(localized: "Distance", comment: "Stat tile label"),
        value: viewModel.distanceValue,
        unit: viewModel.distanceUnit
      )
      DriveStatTile(
        icon: "clock",
        label: String(localized: "Duration", comment: "Stat tile label"),
        value: viewModel.durationValue,
        unit: viewModel.durationUnit
      )
      DriveStatTile(
        icon: "speedometer",
        label: String(localized: "Avg Speed", comment: "Stat tile label"),
        value: viewModel.avgSpeedValue,
        unit: viewModel.avgSpeedUnit
      )
    }
  }

  private var endpointsCard: some View {
    VStack(spacing: 0) {
      IconRow(
        title: viewModel.startPlace ?? String(localized: "Unknown", comment: "Unknown place name"),
        subtitle: String(localized: "Departure", comment: "Endpoint row subtitle"),
        trailing: viewModel.departureTime
      ) {
        Circle()
          .fill(Color.green)
          .frame(width: 13, height: 13)
          .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
          .shadow(color: .black.opacity(0.15), radius: 1)
      }
      
      Divider().padding(.leading, 52)
      
      IconRow(
        title: viewModel.endPlace ?? String(localized: "Unknown", comment: "Unknown place name"),
        subtitle: String(localized: "Arrival", comment: "Endpoint row subtitle"),
        trailing: viewModel.arrivalTime
      ) {
        Image(systemName: Icons.finishFlag)
          .font(.body.weight(.medium))
          .foregroundStyle(.red)
          .dynamicTypeSize(.xSmall ... .xxxLarge)
      }
    }
    .cardBackground(cornerRadius: 16)
  }

  private var metadataCard: some View {
    VStack(spacing: 0) {
      IconRow(title: String(localized: "Top Speed", comment: "Metadata row"), trailing: viewModel.topSpeed) {
        Image(systemName: Icons.speed)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
      
      Divider().padding(.leading, 52)
      
      IconRow(title: String(localized: "Track Points", comment: "Metadata row"), trailing: viewModel.trackPoints) {
        Image(systemName: Icons.location)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
      
      Divider().padding(.leading, 52)
      
      IconRow(title: String(localized: "Started by", comment: "Metadata row"), trailing: viewModel.triggerDisplayName) {
        Image(systemName: Icons.gpsSignal)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
    }
    .cardBackground(cornerRadius: 16)
  }

  private var shareDriveButton: some View {
    Button {
      viewModel.showSharingDialog = true
    } label: {
      Label(String(localized: "Share Drive", comment: "Share button"), systemImage: Icons.sharing)
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .cardBackground(cornerRadius: 16)
  }
}

// MARK: - Presentation Modifiers

private struct FullScreenMapModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel

  func body(content: Content) -> some View {
    content.navigationDestination(isPresented: $viewModel.showingFullScreenMap) {
      FullScreenMapView(drive: viewModel.drive)
    }
  }
}

private struct ExportShareSheetModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel

  func body(content: Content) -> some View {
    content.sheet(item: $viewModel.exportedFile) { file in
      ActivityViewController(activityItems: [file.url])
    }
  }
}

private struct ExportErrorAlertModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel

  func body(content: Content) -> some View {
    content.alert(
      String(localized: "Export Failed", comment: "Export error alert title"),
      isPresented: Binding(get: { viewModel.exportError != nil }, set: { if !$0 { viewModel.exportError = nil } }),
      presenting: viewModel.exportError
    ) { _ in
      Button(String(localized: "OK", comment: "Dismiss export error alert")) { viewModel.exportError = nil }
    } message: { error in
      Text(error)
    }
  }
}

private struct DeleteDriveAlertModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel
  let dismiss: () -> Void

  func body(content: Content) -> some View {
    content.alert(
      String(localized: "Delete Drive", comment: "Delete confirmation alert title"),
      isPresented: $viewModel.showingDeleteConfirmation
    ) {
      Button.delete {
        viewModel.deleteDrive()
        dismiss()
      }
      Button.cancel()
    } message: {
      Text(String(localized: "This drive and all its data will be permanently deleted.", comment: "Delete drive confirmation message"))
    }
  }
}

private struct EditDriveSheetModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel

  func body(content: Content) -> some View {
    content.sheet(isPresented: $viewModel.showingEditDrive) {
      EditDriveView(drive: viewModel.drive)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
}

private struct ShareDriveDialogModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel

  func body(content: Content) -> some View {
    content.confirmationDialog(
      String(localized: "Share Drive", comment: "Share drive dialog title"),
      isPresented: $viewModel.showSharingDialog
    ) {
      Button(String(localized: "Share GPX", comment: "Share drive as GPX")) { viewModel.shareDriveGPX() }
      Button(String(localized: "Share PNG", comment: "Share drive as PNG")) { viewModel.shareDrivePNG() }
      Button.cancel()
    }
  }
}

private struct DriveOptionsDialogModifier: ViewModifier {
  @Bindable var viewModel: DriveDetailViewModel

  func body(content: Content) -> some View {
    content.confirmationDialog(
      String(localized: "Drive Options", comment: "More menu title"),
      isPresented: $viewModel.showingMoreMenu
    ) {
      Button(String(localized: "Edit Drive Details", comment: "More menu action")) {
        viewModel.showingEditDrive = true
      }
      Button(String(localized: "Delete Drive", comment: "More menu action"), role: .destructive) {
        viewModel.showingDeleteConfirmation = true
      }
      Button.cancel()
    }
  }
}

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  let drive = PreviewSampleData.sampleDrive(in: container.mainContext)
  return NavigationStack {
    DriveDetailView(drive: drive)
  }
  .modelContainer(container)
}
