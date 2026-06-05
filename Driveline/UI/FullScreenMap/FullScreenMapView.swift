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

  @State private var viewModel: FullScreenMapViewModel

  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(drive: Drive) {
    _viewModel = State(initialValue: FullScreenMapViewModel(drive: drive))
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      Map(initialPosition: viewModel.cameraPosition) {
        DriveMapContent(coordinates: viewModel.coordinates)
      }
      .mapStyle(.standard(emphasis: .muted))
      .ignoresSafeArea()

      VStack {
        HStack {
          GlassButton(systemImage: Icons.chevronLeft, accessibilityLabel: LocalizedStringResource("Back", comment: "Accessibility label for the back button on the full screen map")) { dismiss() }
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
    VStack(alignment: .leading, spacing: 10) {
      Text(viewModel.name)
        .font(.body.weight(.semibold))
        .foregroundStyle(Color(.label))

      HStack(spacing: 0) {
        statChip(value: viewModel.distanceValue, unit: viewModel.distanceUnit)
        Divider().frame(height: 28).padding(.horizontal, 12)
        statChip(value: viewModel.durationValue, unit: viewModel.durationUnit)
        Divider().frame(height: 28).padding(.horizontal, 12)
        statChip(value: viewModel.avgSpeedValue, unit: viewModel.avgSpeedUnit)
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
      Text(unit)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

}

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  let drive = PreviewSampleData.sampleDrive(in: container.mainContext)
  return NavigationStack {
    FullScreenMapView(drive: drive)
  }
  .modelContainer(container)
}
