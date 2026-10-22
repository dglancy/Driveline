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
    Map(position: $mapState.cameraPosition) {
      DriveMapContent(segments: mapState.coordinateSegments)
    }
    .mapStyle(.standard(emphasis: .muted))
    .ignoresSafeArea()
    .accessibilityLabel(Text(DriveDetailPresenter(drive: mapState.drive).routeAccessibilityLabel))
    .task { await mapState.loadRoute() }
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button {
          dismiss()
        } label: {
          Label(
            String(localized: "Back", comment: "Full screen map toolbar action"),
            systemImage: Icons.Navigation.chevronLeft
          )
        }
      }
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
