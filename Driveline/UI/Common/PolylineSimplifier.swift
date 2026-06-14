//
//  PolylineSimplifier.swift
//  Driveline
//
//  Created by Damien Glancy on 14/06/2026.
//

import CoreLocation
import Foundation

nonisolated enum PolylineSimplifier {

  // MARK: - Actions

  static func simplify(_ coordinates: [CLLocationCoordinate2D], toleranceMeters: Double) -> [CLLocationCoordinate2D] {
    guard coordinates.count > 2, toleranceMeters > 0 else { return coordinates }

    var keep = [Bool](repeating: false, count: coordinates.count)
    keep[0] = true
    keep[coordinates.count - 1] = true

    var stack: [(Int, Int)] = [(0, coordinates.count - 1)]
    while let (start, end) = stack.popLast() {
      guard end > start + 1 else { continue }

      var maxDistance = 0.0
      var maxIndex = start
      for index in (start + 1)..<end {
        let distance = perpendicularDistanceMeters(
          coordinates[index],
          lineStart: coordinates[start],
          lineEnd: coordinates[end]
        )
        if distance > maxDistance {
          maxDistance = distance
          maxIndex = index
        }
      }

      if maxDistance > toleranceMeters {
        keep[maxIndex] = true
        stack.append((start, maxIndex))
        stack.append((maxIndex, end))
      }
    }

    return zip(coordinates, keep).compactMap { $1 ? $0 : nil }
  }

  // MARK: - Private

  private static func perpendicularDistanceMeters(
    _ point: CLLocationCoordinate2D,
    lineStart: CLLocationCoordinate2D,
    lineEnd: CLLocationCoordinate2D
  ) -> Double {
    let metresPerDegreeLatitude = 111_320.0
    let metresPerDegreeLongitude = metresPerDegreeLatitude * cos(lineStart.latitude * .pi / 180)

    let ax = lineStart.longitude * metresPerDegreeLongitude
    let ay = lineStart.latitude * metresPerDegreeLatitude
    let bx = lineEnd.longitude * metresPerDegreeLongitude
    let by = lineEnd.latitude * metresPerDegreeLatitude
    let px = point.longitude * metresPerDegreeLongitude
    let py = point.latitude * metresPerDegreeLatitude

    let dx = bx - ax
    let dy = by - ay
    let lengthSquared = dx * dx + dy * dy
    guard lengthSquared > 0 else { return hypot(px - ax, py - ay) }

    let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / lengthSquared))
    let projectionX = ax + t * dx
    let projectionY = ay + t * dy
    return hypot(px - projectionX, py - projectionY)
  }
}
