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
  let segments: [[CLLocationCoordinate2D]]
  let positionCount: Int
  let maxSpeedMetresPerSecond: CLLocationSpeed
}

// MARK: - DrivePositionLoader

@ModelActor
actor DrivePositionsLoader {

  // MARK: - Actions

  func simplifiedCoordinates(forDriveID driveID: UUID, toleranceMeters: Double) -> [[CLLocationCoordinate2D]] {
    splitIntoSegments(positions(forDriveID: driveID)).map { segment in
      let coords = segment.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
      return PolylineSimplifier.simplify(coords, toleranceMeters: toleranceMeters)
    }
  }

  func routeData(forDriveID driveID: UUID, toleranceMeters: Double) -> RouteData {
    let positions = positions(forDriveID: driveID)
    let segments = splitIntoSegments(positions).map { segment in
      let coords = segment.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
      return PolylineSimplifier.simplify(coords, toleranceMeters: toleranceMeters)
    }
    let maxSpeed = max(0, positions.map(\.speed).max() ?? 0)
    return RouteData(segments: segments, positionCount: positions.count, maxSpeedMetresPerSecond: maxSpeed)
  }

  // MARK: - Private

  private func positions(forDriveID driveID: UUID) -> [Position] {
    let descriptor = FetchDescriptor<Position>(
      predicate: #Predicate { $0.drive?.id == driveID },
      sortBy: [SortDescriptor(\.timestamp, order: .forward)]
    )
    return (try? modelContext.fetch(descriptor)) ?? []
  }

  private func splitIntoSegments(_ positions: [Position]) -> [[Position]] {
    guard !positions.isEmpty else { return [] }
    var segments: [[Position]] = [[positions[0]]]
    for i in 1..<positions.count {
      let gap = positions[i].timestamp.timeIntervalSince(positions[i - 1].timestamp)
      if gap > Constants.Configuration.trackSegmentGapThreshold {
        segments.append([positions[i]])
      } else {
        segments[segments.count - 1].append(positions[i])
      }
    }
    return segments
  }
}
