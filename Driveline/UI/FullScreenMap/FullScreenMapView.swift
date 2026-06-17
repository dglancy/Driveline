//
//  FullScreenMapView.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import MapKit
import SwiftData
import SwiftUI

struct FullScreenMapView: View {

  // MARK: - Properties

  @State private var mapState: FullScreenMapState

  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(drive: Drive, modelContainer: ModelContainer) {
    _mapState = State(initialValue: FullScreenMapState(drive: drive, modelContainer: modelContainer))
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      Map(position: $mapState.cameraPosition) {
        DriveMapContent(coordinates: mapState.coordinates)
      }
      .mapStyle(.standard(emphasis: .muted))
      .ignoresSafeArea()
      .accessibilityLabel(Text(DriveDetailPresenter(drive: mapState.drive).routeAccessibilityLabel))
      .task { await mapState.loadRoute() }

      VStack {
        HStack {
          GlassButton(systemImage: Icons.Navigation.chevronLeft, accessibilityLabel: LocalizedStringResource("Back", comment: "Accessibility label for the back button on the full screen map")) { dismiss() }
          Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)

        Spacer()

        infoCard
          .padding(.horizontal, 16)
          .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  // MARK: - Private Views

  private var infoCard: some View {
    let stats = DriveStatsPresenter(drive: mapState.drive)
    return VStack(spacing: 10) {
      Text(mapState.drive.displayName)
        .font(.body.weight(.semibold))
        .foregroundStyle(Color(.label))
        .dynamicTypeSize(.xSmall ... .accessibility1)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(.center)

      HStack(spacing: 0) {
        statChip(value: stats.distanceValue, unit: stats.distanceUnit)
        Divider().frame(height: 28).padding(.horizontal, 12)
        statChip(value: stats.durationValue, unit: stats.durationUnit)
        Divider().frame(height: 28).padding(.horizontal, 12)
        statChip(value: stats.avgSpeedValue, unit: stats.avgSpeedUnit)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
  }

  private func statChip(value: String, unit: String) -> some View {
    VStack(spacing: 1) {
      Text(value)
        .font(.body.weight(.semibold))
        .dynamicTypeSize(.xSmall ... .xxxLarge)
      Text(unit)
        .font(.caption)
        .foregroundStyle(.secondary)
        .dynamicTypeSize(.xSmall ... .xxxLarge)
    }
  }

}

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  let drive = PreviewSampleData.sampleDrive(in: container.mainContext)
  return NavigationStack {
    FullScreenMapView(drive: drive, modelContainer: container)
  }
  .modelContainer(container)
}
