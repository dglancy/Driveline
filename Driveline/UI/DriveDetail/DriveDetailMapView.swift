//
//  DriveDetailMapView.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct DriveDetailMapView: View {

  // MARK: - Properties

  let segments: [[CLLocationCoordinate2D]]
  @Binding var cameraPosition: MapCameraPosition
  let accessibilityLabel: String
  var interactionModes: MapInteractionModes = []

  // MARK: - Body

  var body: some View {
    Map(position: $cameraPosition, interactionModes: interactionModes) {
      DriveMapContent(segments: segments)
    }
    .mapStyle(.standard(emphasis: .muted))
    .accessibilityElement()
    .accessibilityLabel(Text(accessibilityLabel))
  }
}
