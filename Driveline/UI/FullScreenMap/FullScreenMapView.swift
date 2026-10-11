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
        DriveMapContent(segments: mapState.coordinateSegments)
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
      }
    }
    .toolbar(.hidden, for: .navigationBar)
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
