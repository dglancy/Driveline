//
//  DrivePositionsLoader.swift
//  Driveline
//
//  Created by Damien Glancy on 14/06/2026.
//

import CoreLocation
import Foundation
import SwiftData

// MARK: - RouteData

struct RouteData: Sendable {
  let coordinates: [CLLocationCoordinate2D]
  let positionCount: Int
  let maxSpeedMetresPerSecond: CLLocationSpeed
}

// MARK: - DrivePositionLoader

@ModelActor
actor DrivePositionsLoader {

  // MARK: - Actions

  func simplifiedCoordinates(forDriveID driveID: UUID, toleranceMeters: Double) -> [CLLocationCoordinate2D] {
    let coordinates = positions(forDriveID: driveID).map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    return PolylineSimplifier.simplify(coordinates, toleranceMeters: toleranceMeters)
  }

  func routeData(forDriveID driveID: UUID, toleranceMeters: Double) -> RouteData {
    let positions = positions(forDriveID: driveID)
    let coordinates = positions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
    let simplified = PolylineSimplifier.simplify(coordinates, toleranceMeters: toleranceMeters)
    let maxSpeed = max(0, positions.map(\.speed).max() ?? 0)
    return RouteData(coordinates: simplified, positionCount: positions.count, maxSpeedMetresPerSecond: maxSpeed)
  }

  // MARK: - Private

  private func positions(forDriveID driveID: UUID) -> [Position] {
    let descriptor = FetchDescriptor<Position>(
      predicate: #Predicate { $0.drive?.id == driveID },
      sortBy: [SortDescriptor(\.timestamp, order: .forward)]
    )
    return (try? modelContext.fetch(descriptor)) ?? []
  }
}
