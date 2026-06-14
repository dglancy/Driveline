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

  let coordinates: [CLLocationCoordinate2D]
  @Binding var cameraPosition: MapCameraPosition

  // MARK: - Body

  var body: some View {
    Map(position: $cameraPosition, interactionModes: []) {
      DriveMapContent(coordinates: coordinates)
    }
    .mapStyle(.standard(emphasis: .muted))
  }
}
