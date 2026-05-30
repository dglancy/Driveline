//
//  Untitled.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
import CoreLocation
import Foundation
import Testing

struct CoreLocationExtensionsTests {

  // MARK: - Tests

  @Test
  func mapsSettingsStringsToActivityType() async {
    #expect(CLActivityType(fromSettings: "automotive") == .automotiveNavigation)
    #expect(CLActivityType(fromSettings: "fitness") == .fitness)
    #expect(CLActivityType(fromSettings: "other") == .other)
    #expect(CLActivityType(fromSettings: "flight") == .airborne)
  }

  @Test
  func defaultsToOtherNavigation() async {
    #expect(CLActivityType(fromSettings: "unexpected-value") == .otherNavigation)
  }
  
  @Test
  func activityTypeSystemImageName() {
    #expect(CLActivityType.automotiveNavigation.systemImageName == "car.fill")
    #expect(CLActivityType.fitness.systemImageName == "figure.walk")
    #expect(CLActivityType.airborne.systemImageName == "airplane")
    #expect(CLActivityType.other.systemImageName == "location.fill")
    #expect(CLActivityType.otherNavigation.systemImageName == "bicycle")
  }
  
  @Test
  func activityTypeTitle() {
    #expect(CLActivityType.automotiveNavigation.title == "Car")
    #expect(CLActivityType.fitness.title == "Person")
    #expect(CLActivityType.airborne.title == "Airplane")
    #expect(CLActivityType.other.title == "Other")
    #expect(CLActivityType.otherNavigation.title == "Bicycle")
  }
  
  @Test
  func speedKilometersPerHourZero() {
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date())
    #expect(location.speedKilometersPerHour == 0)
  }
  
  @Test
  func speedKilometersPerHourNonZero() {
    // 5 km/h = 1.3888889 m/s
    let speedMetersPerSecond = 5.0 / 3.6
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: speedMetersPerSecond, speedAccuracy: 0.5, timestamp: Date())
    #expect(location.speedKilometersPerHour == 5.0)
  }
}

