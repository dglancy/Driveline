//
//  DriveDetailView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI
import TipKit

struct DriveDetailView: View {

  // MARK: - Properties

  @State private var driveState: DriveDetailState
  @State private var showingFullScreenMap = false
  @State private var showingDeleteConfirmation = false
  @State private var showingEditDrive = false

  private let renameDriveTip = EditDriveTip()

  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService
  @Environment(\.modelContext) private var modelContext

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

      GeometryReader { geometry in
        VStack(spacing: 0) {
          DriveDetailMapView(segments: driveState.coordinateSegments, cameraPosition: $driveState.cameraPosition, accessibilityLabel: presenter.routeAccessibilityLabel)
            .frame(height: min(280, max(140, geometry.size.height * 0.4)))
            .task { await driveState.loadRoute() }

          ScrollView {
            VStack(alignment: .leading, spacing: 14) {
              driveHeader(presenter: presenter)
              statTiles
              endpointsCard(presenter: presenter)
              DriveDetailWeatherCard(presenter: presenter) { driveState.loadWeatherAttribution() }
              DriveDetailMetadataCard(presenter: presenter, maxSpeedMPS: driveState.maxSpeedMetresPerSecond, positionCount: driveState.positionCount)
              shareDriveButton
              Spacer()
              weatherAttributionFooter
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
          }
          .padding(.top, 20)
          .contentMargins(.top, 0, for: .scrollContent)
        }
      }
    }
    .navigationBarBackButtonHidden()
    .toolbar {
      DriveDetailActionToolbar(
          renameDriveTip: renameDriveTip,
          onBack: { dismiss() },
          onEdit: {
            renameDriveTip.invalidate(reason: .actionPerformed)
            showingEditDrive = true
          },
          onDelete: { showingDeleteConfirmation = true },
          onShowFullScreenMap: { showingFullScreenMap = true }
      )
    }
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

  // MARK: - Private Views

  private func driveHeader(presenter: DriveDetailPresenter) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(presenter.name)
        .font(.title.weight(.bold))
        .foregroundStyle(Color(.label))
        .lineLimit(2)
        .minimumScaleFactor(0.1)
        .dynamicTypeSize(.xSmall ... .accessibility1)
      Text(presenter.dateString)
        .font(.callout)
        .foregroundStyle(.secondary)
        .dynamicTypeSize(.xSmall ... .accessibility1)
    }
  }

  private var statTiles: some View {
    let stats = DriveStatsPresenter(drive: driveState.drive)
    return HStack(spacing: 10) {
      DriveStatTile(
        icon: "ruler",
        label: String(localized: "Distance", comment: "Stat tile label"),
        value: stats.distanceValue,
        unit: stats.distanceUnit
      )
      DriveStatTile(
        icon: "clock",
        label: String(localized: "Duration", comment: "Stat tile label"),
        value: stats.durationValue,
        unit: stats.durationUnit
      )
      DriveStatTile(
        icon: "speedometer",
        label: String(localized: "Avg Speed", comment: "Stat tile label"),
        value: stats.avgSpeedValue,
        unit: stats.avgSpeedUnit
      )
    }
  }

  private func endpointsCard(presenter: DriveDetailPresenter) -> some View {
    VStack(spacing: 0) {
      IconRow(
        title: presenter.startPlace ?? String(localized: "Unknown", comment: "Unknown place name"),
        subtitle: String(localized: "Departure", comment: "Endpoint row subtitle"),
        trailing: presenter.departureTime
      ) {
        Circle()
          .fill(Color.green)
          .frame(width: 13, height: 13)
          .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
          .shadow(color: .black.opacity(0.15), radius: 1)
      }

      Divider().padding(.leading, 52)

      IconRow(
        title: presenter.endPlace ?? String(localized: "Unknown", comment: "Unknown place name"),
        subtitle: String(localized: "Arrival", comment: "Endpoint row subtitle"),
        trailing: presenter.arrivalTime
      ) {
        Image(systemName: Icons.Drive.finishFlag)
          .font(.body.weight(.medium))
          .foregroundStyle(.red)
          .dynamicTypeSize(.xSmall ... .xxxLarge)
      }
    }
    .cardBackground(cornerRadius: 16)
  }

  @ViewBuilder
  private var weatherAttributionFooter: some View {
    if let legalURL = driveState.weatherAttributionLegalURL,
       let lightMarkURL = driveState.weatherAttributionLightMarkURL,
       let darkMarkURL = driveState.weatherAttributionDarkMarkURL {
      VStack(spacing: 4) {
        Link(destination: legalURL) {
          AsyncImage(url: colorScheme == .dark ? darkMarkURL : lightMarkURL) { image in
            image.resizable().scaledToFit()
          } placeholder: {
            EmptyView()
          }
          .frame(height: 14)
        }
        Link(String(localized: "Weather data provided by Apple Weather", comment: "Weather attribution footer link"), destination: legalURL)
          .font(.caption2)
          .foregroundStyle(Color(.secondaryLabel))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    }
  }

  private var shareDriveButton: some View {
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
      Label(String(localized: "Share Drive", comment: "Share button"), systemImage: Icons.Options.sharing)
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(alignment: .trailing) {
          if driveState.isPreparingExport {
            ProgressView().padding(.trailing, 16)
          }
        }
    }
    .disabled(!driveState.canExport || driveState.isPreparingExport)
    .cardBackground(cornerRadius: 16)
  }
}

// MARK: - DriveDetailActionToolbar

private struct DriveDetailActionToolbar: ToolbarContent {

  let renameDriveTip: EditDriveTip
  let onBack: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void
  let onShowFullScreenMap: () -> Void

  var body: some ToolbarContent {
    ToolbarItem(placement: .navigation) {
      Button(action: onBack) {
        Label(String(localized: "Back", comment: "Drive detail toolbar action"), systemImage: Icons.Navigation.chevronLeft)
      }
    }

    ToolbarItemGroup(placement: .bottomBar) {
      Button(action: onEdit) {
        Label(String(localized: "Edit Drive Details", comment: "Drive detail toolbar action"), systemImage: "pencil")
      }
      .popoverTip(renameDriveTip)

      Button(action: onShowFullScreenMap) {
        Label(String(localized: "Full screen map", comment: "Drive detail toolbar action"), systemImage: Icons.Options.viewfinder)
      }

      Button(role: .destructive, action: onDelete) {
        Label(String(localized: "Delete Drive", comment: "Drive detail toolbar action"), systemImage: "trash")
      }
    }
  }
}

// MARK: - DriveDetailWeatherCard

private struct DriveDetailWeatherCard: View {

  // MARK: - Properties

  let presenter: DriveDetailPresenter
  let onLoadAttribution: () -> Void

  // MARK: - Body

  var body: some View {
    if presenter.hasWeather {
      VStack(spacing: 0) {
        if let symbol = presenter.startWeatherSymbol,
           let description = presenter.startWeatherDescription {
          IconRow(
            title: description,
            subtitle: String(localized: "At Departure", comment: "Weather row subtitle"),
            trailing: presenter.startWeatherTemperature
          ) {
            Image(systemName: symbol)
              .symbolRenderingMode(.multicolor)
              .font(.callout)
              .frame(width: 24)
              .dynamicTypeSize(.xSmall ... .accessibility1)
          }
        }

        if let symbol = presenter.endWeatherSymbol,
           let description = presenter.endWeatherDescription {
          Divider().padding(.leading, 52)
          IconRow(
            title: description,
            subtitle: String(localized: "At Arrival", comment: "Weather row subtitle"),
            trailing: presenter.endWeatherTemperature
          ) {
            Image(systemName: symbol)
              .symbolRenderingMode(.multicolor)
              .font(.callout)
              .frame(width: 24)
              .dynamicTypeSize(.xSmall ... .accessibility1)
          }
        }
      }
      .cardBackground(cornerRadius: 16)
      .task { onLoadAttribution() }
    }
  }
}

// MARK: - DriveDetailMetadataCard

private struct DriveDetailMetadataCard: View {

  // MARK: - Properties

  let presenter: DriveDetailPresenter
  let maxSpeedMPS: CLLocationSpeed
  let positionCount: Int

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      if presenter.hasCategory {
        IconRow(title: String(localized: "Category", comment: "Metadata row"), trailing: presenter.categoryDisplayName) {
          Image(systemName: Icons.Stats.category)
            .font(.callout)
            .foregroundStyle(.secondary)
            .dynamicTypeSize(.xSmall ... .accessibility1)
        }

        Divider().padding(.leading, 52)
      }

      IconRow(title: String(localized: "Top Speed", comment: "Metadata row"), trailing: presenter.topSpeed(maxSpeedMPS: maxSpeedMPS)) {
        Image(systemName: Icons.Stats.speed)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }

      Divider().padding(.leading, 52)

      IconRow(title: String(localized: "Track Points", comment: "Metadata row"), trailing: presenter.trackPoints(count: positionCount)) {
        Image(systemName: Icons.Stats.location)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }

      Divider().padding(.leading, 52)

      IconRow(title: String(localized: "Started by", comment: "Metadata row"), trailing: presenter.triggerDisplayName) {
        Image(systemName: Icons.Stats.gpsSignal)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
    }
    .cardBackground(cornerRadius: 16)
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
