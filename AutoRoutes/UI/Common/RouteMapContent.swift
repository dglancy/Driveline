//
//  RouteMapContent.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct RouteMapContent: MapContent {

  // MARK: - Properties

  let coordinates: [CLLocationCoordinate2D]

  // MARK: - Body

  var body: some MapContent {
    if coordinates.count > 1 {
      MapPolyline(coordinates: coordinates)
        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    if let start = coordinates.first {
      Annotation("", coordinate: start, anchor: .center) {
        RouteStartAnnotation()
      }
    }

    if let end = coordinates.last, coordinates.count > 1 {
      Annotation("", coordinate: end, anchor: .bottom) {
        RouteEndAnnotation()
      }
    }
  }
}
