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
  let cameraPosition: MapCameraPosition

  // MARK: - Body

  var body: some View {
    Map(initialPosition: cameraPosition) {
      DriveMapContent(coordinates: coordinates)
    }
    .mapStyle(.standard(emphasis: .muted))
  }
}
