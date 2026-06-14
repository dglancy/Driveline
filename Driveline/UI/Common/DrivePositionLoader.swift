//
//  DrivePositionLoader.swift
//  Driveline
//
//  Created by Damien Glancy on 14/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

@ModelActor
actor DrivePositionLoader {

  // MARK: - Actions

  func simplifiedCoordinates(forDriveID driveID: UUID, toleranceMeters: Double) -> [CLLocationCoordinate2D] {
    let descriptor = FetchDescriptor<Position>(
      predicate: #Predicate { $0.drive?.id == driveID },
      sortBy: [SortDescriptor(\.timestamp, order: .forward)]
    )
    guard let positions = try? modelContext.fetch(descriptor) else { return [] }
    let coordinates = positions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    return PolylineSimplifier.simplify(coordinates, toleranceMeters: toleranceMeters)
  }
}
