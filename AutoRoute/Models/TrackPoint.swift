//
//  TrackPoint.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import SwiftData

@Model
final class TrackPoint {

  // MARK: - Properties

  var timestamp: Date
  var latitude: Double
  var longitude: Double
  var altitude: Double
  var speed: Double // negative means unavailable, matching CLLocation
  var horizontalAccuracy: Double

  var route: Route?

  // MARK: - Lifecycle

  init(
    timestamp: Date,
    latitude: Double,
    longitude: Double,
    altitude: Double,
    speed: Double,
    horizontalAccuracy: Double
  ) {
    self.timestamp = timestamp
    self.latitude = latitude
    self.longitude = longitude
    self.altitude = altitude
    self.speed = speed
    self.horizontalAccuracy = horizontalAccuracy
  }
}
