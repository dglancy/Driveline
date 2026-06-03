//
//  Position.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation
import SwiftData

@Model
final class Position {

  // MARK: - Properties

  var timestamp: Date
  var latitude: CLLocationDegrees
  var longitude: CLLocationDegrees
  var altitude: CLLocationDistance
  var horizontalAccuracy: CLLocationAccuracy
  var verticalAccuracy: CLLocationAccuracy
  var course: CLLocationDirection
  var courseAccuracy: CLLocationDirectionAccuracy
  var speed: CLLocationSpeed
  var speedAccuracy: CLLocationSpeedAccuracy

  var route: Route?

  // MARK: - Computed Property

  var location: CLLocation {
    CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: altitude,
               horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course,
               courseAccuracy: courseAccuracy, speed: speed, speedAccuracy: speedAccuracy, timestamp: timestamp)
  }

  // MARK: - Lifecycle

  init(
    timestamp: Date = .now,
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees,
    altitude: CLLocationDistance,
    horizontalAccuracy: CLLocationAccuracy,
    verticalAccuracy: CLLocationAccuracy,
    course: CLLocationDirection,
    courseAccuracy: CLLocationDirectionAccuracy,
    speed: CLLocationSpeed,
    speedAccuracy: CLLocationSpeedAccuracy
  ) {
    self.timestamp = timestamp
    self.latitude = latitude
    self.longitude = longitude
    self.altitude = altitude
    self.horizontalAccuracy = horizontalAccuracy
    self.verticalAccuracy = verticalAccuracy
    self.course = course
    self.courseAccuracy = courseAccuracy
    self.speed = speed
    self.speedAccuracy = speedAccuracy
  }
}
