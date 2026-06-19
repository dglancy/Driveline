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

  // MARK: - Body

  var body: some View {
    Map(position: $cameraPosition, interactionModes: []) {
      DriveMapContent(segments: segments)
    }
    .mapStyle(.standard(emphasis: .muted))
    .accessibilityElement()
    .accessibilityLabel(Text(accessibilityLabel))
  }
}
