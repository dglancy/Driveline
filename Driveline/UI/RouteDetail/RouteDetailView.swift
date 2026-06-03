//
//  RouteDetailView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import MapKit
import SwiftData
import SwiftUI

struct RouteDetailView: View {

  // MARK: - Properties

  @State private var viewModel: RouteDetailViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  private let mapHeight: CGFloat = 280

  // MARK: - Lifecycle

  init(route: Route) {
    _viewModel = State(initialValue: RouteDetailViewModel(route: route))
  }

  // MARK: - Body

  var body: some View {
    ZStack(alignment: .top) {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        RouteDetailMapView(coordinates: viewModel.coordinates, cameraPosition: viewModel.cameraPosition)
          .frame(height: mapHeight)
          .overlay(alignment: .topLeading) {
            GlassButton(systemImage: "chevron.left", accessibilityLabel: "Back") { dismiss() }
              .padding(14)
          }
          .overlay(alignment: .topTrailing) {
            GlassButton(systemImage: "ellipsis", accessibilityLabel: "More options") {
              viewModel.showingMoreMenu = true
            }
            .padding(14)
          }
          .overlay(alignment: .bottomTrailing) {
            GlassButton(systemImage: "viewfinder", accessibilityLabel: "Full screen map") {
              viewModel.showingFullScreenMap = true
            }
            .padding(14)
          }

        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            routeHeader
            statTiles
            endpointsCard
            metadataCard
            shareRouteButton
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 24)
        }
        .padding(.top, 20)
        .contentMargins(.top, 0, for: .scrollContent)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .modifier(FullScreenMapModifier(viewModel: viewModel))
    .modifier(ExportShareSheetModifier(viewModel: viewModel))
    .modifier(ExportErrorAlertModifier(viewModel: viewModel))
    .modifier(DeleteRouteAlertModifier(viewModel: viewModel, modelContext: modelContext, dismiss: { dismiss() }))
    .modifier(EditRouteSheetModifier(viewModel: viewModel))
    .modifier(RouteOptionsDialogModifier(viewModel: viewModel))
  }

  // MARK: - Private Views

  private var routeHeader: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(viewModel.name)
        .font(.title.weight(.bold))
        .foregroundStyle(Color(.label))
      Text(viewModel.dateString)
        .font(.callout)
        .foregroundStyle(.secondary)
    }
  }

  private var statTiles: some View {
    HStack(spacing: 10) {
      RouteStatTile(
        icon: "ruler",
        label: String(localized: "Distance", comment: "Stat tile label"),
        value: viewModel.distanceValue,
        unit: viewModel.distanceUnit
      )
      RouteStatTile(
        icon: "clock",
        label: String(localized: "Duration", comment: "Stat tile label"),
        value: viewModel.durationValue,
        unit: viewModel.durationUnit
      )
      RouteStatTile(
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
        Image(systemName: SystemImage.finishFlag)
          .font(.body.weight(.medium))
          .foregroundStyle(.red)
      }
    }
    .cardBackground(cornerRadius: 16)
  }

  private var metadataCard: some View {
    VStack(spacing: 0) {
      IconRow(title: String(localized: "Top Speed", comment: "Metadata row"), trailing: viewModel.topSpeed) {
        Image(systemName: SystemImage.speed)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Divider().padding(.leading, 52)
      IconRow(title: String(localized: "Track Points", comment: "Metadata row"), trailing: viewModel.trackPoints) {
        Image(systemName: SystemImage.location)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
      Divider().padding(.leading, 52)
      IconRow(title: String(localized: "Started by", comment: "Metadata row"), trailing: viewModel.triggerDisplayName) {
        Image(systemName: SystemImage.gpsSignal)
          .font(.callout)
          .foregroundStyle(.secondary)
      }
    }
    .cardBackground(cornerRadius: 16)
  }

  private var shareRouteButton: some View {
    Button {
      viewModel.showSharingDialog = true
    } label: {
      Label(String(localized: "Share Route", comment: "Share button"), systemImage: "square.and.arrow.up")
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .cardBackground(cornerRadius: 16)
    .alert(String(localized: "Share Route", comment: "Share route alert title"), isPresented: $viewModel.showSharingDialog) {
      Button(String(localized: "Share GPX", comment: "Share route as GPX")) { viewModel.shareRouteGPX() }
      Button(String(localized: "Share PNG", comment: "Share route as PNG")) { viewModel.shareRoutePNG() }
      Button.cancel()
    }
  }
}

// MARK: - Presentation Modifiers

private struct FullScreenMapModifier: ViewModifier {
  @Bindable var viewModel: RouteDetailViewModel

  func body(content: Content) -> some View {
    content.navigationDestination(isPresented: $viewModel.showingFullScreenMap) {
      FullScreenMapView(route: viewModel.route)
    }
  }
}

private struct ExportShareSheetModifier: ViewModifier {
  @Bindable var viewModel: RouteDetailViewModel

  func body(content: Content) -> some View {
    content.sheet(item: $viewModel.exportedFile) { file in
      ActivityViewController(activityItems: [file.url])
    }
  }
}

private struct ExportErrorAlertModifier: ViewModifier {
  @Bindable var viewModel: RouteDetailViewModel

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

private struct DeleteRouteAlertModifier: ViewModifier {
  @Bindable var viewModel: RouteDetailViewModel
  let modelContext: ModelContext
  let dismiss: () -> Void

  func body(content: Content) -> some View {
    content.alert(
      String(localized: "Delete Route", comment: "Delete confirmation alert title"),
      isPresented: $viewModel.showingDeleteConfirmation
    ) {
      Button.delete {
        viewModel.deleteRoute(using: modelContext)
        dismiss()
      }
      Button.cancel()
    } message: {
      Text(String(localized: "This route and all its data will be permanently deleted.", comment: "Delete route confirmation message"))
    }
  }
}

private struct EditRouteSheetModifier: ViewModifier {
  @Bindable var viewModel: RouteDetailViewModel

  func body(content: Content) -> some View {
    content.sheet(isPresented: $viewModel.showingEditRoute) {
      EditRouteView(route: viewModel.route)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
  }
}

private struct RouteOptionsDialogModifier: ViewModifier {
  @Bindable var viewModel: RouteDetailViewModel

  func body(content: Content) -> some View {
    content.confirmationDialog(
      String(localized: "Route Options", comment: "More menu title"),
      isPresented: $viewModel.showingMoreMenu
    ) {
      Button(String(localized: "Edit Route Details", comment: "More menu action")) {
        viewModel.showingEditRoute = true
      }
      Button(String(localized: "Delete Route", comment: "More menu action"), role: .destructive) {
        viewModel.showingDeleteConfirmation = true
      }
      Button.cancel()
    }
  }
}

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  let route = PreviewSampleData.sampleRoute(in: container.mainContext)
  return NavigationStack {
    RouteDetailView(route: route)
  }
  .modelContainer(container)
}
