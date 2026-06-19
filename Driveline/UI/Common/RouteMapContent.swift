//
//  DriveMapContent.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct DriveMapContent: MapContent {

  // MARK: - Properties

  let segments: [[CLLocationCoordinate2D]]

  // MARK: - Body

  var body: some MapContent {
    let renderableSegments = segments.filter { $0.count > 1 }
    ForEach(renderableSegments.indices, id: \.self) { index in
      MapPolyline(coordinates: renderableSegments[index])
        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    if let start = segments.first?.first {
      Annotation("", coordinate: start, anchor: .center) {
        DriveStartAnnotation()
      }
    }

    let allCoords = segments.flatMap { $0 }
    if let end = allCoords.last, allCoords.count > 1 {
      Annotation("", coordinate: end, anchor: .bottom) {
        DriveEndAnnotation()
      }
    }
  }
}
