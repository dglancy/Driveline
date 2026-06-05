//
//  ModelTestHelpers.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Foundation
import SwiftData

func makePosition(latitude: Double, longitude: Double, timestamp: Date = .now) -> Position {
  Position(
    latitude: latitude,
    longitude: longitude,
    altitude: 50,
    horizontalAccuracy: 5,
    verticalAccuracy: 3,
    course: 0,
    courseAccuracy: 5,
    speed: 14,
    speedAccuracy: 1
  )
}
