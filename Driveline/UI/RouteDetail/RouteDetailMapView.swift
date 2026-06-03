//
//  RouteDetailMapView.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct RouteDetailMapView: View {

  // MARK: - Properties

  let coordinates: [CLLocationCoordinate2D]
  let cameraPosition: MapCameraPosition

  // MARK: - Body

  var body: some View {
    Map(initialPosition: cameraPosition) {
      RouteMapContent(coordinates: coordinates)
    }
    .mapStyle(.standard(emphasis: .muted))
  }
}
