//
//  PolylineSimplifierTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 14/06/2026.
//

import Testing
import Foundation
import CoreLocation
@testable import Driveline

@Suite("PolylineSimplifier")
struct PolylineSimplifierTests {

  // MARK: - Edge cases

  @Test
  func emptyInputReturnsEmpty() {
    #expect(PolylineSimplifier.simplify([], toleranceMeters: 5).isEmpty)
  }

  @Test
  func twoPointsAreReturnedUnchanged() {
    let coordinates = [
      CLLocationCoordinate2D(latitude: 51.50, longitude: -0.10),
      CLLocationCoordinate2D(latitude: 51.51, longitude: -0.11)
    ]
    let result = PolylineSimplifier.simplify(coordinates, toleranceMeters: 5)
    #expect(result.count == 2)
  }

  @Test
  func zeroToleranceReturnsInputUnchanged() {
    let coordinates = [
      CLLocationCoordinate2D(latitude: 51.500, longitude: -0.100),
      CLLocationCoordinate2D(latitude: 51.501, longitude: -0.100),
      CLLocationCoordinate2D(latitude: 51.502, longitude: -0.100)
    ]
    let result = PolylineSimplifier.simplify(coordinates, toleranceMeters: 0)
    #expect(result.count == 3)
  }

  // MARK: - Simplification

  @Test
  func collinearMidpointsAreRemoved() {
    let coordinates = (0...10).map {
      CLLocationCoordinate2D(latitude: 51.5, longitude: -0.10 + Double($0) * 0.001)
    }
    let result = PolylineSimplifier.simplify(coordinates, toleranceMeters: 5)
    #expect(result.count == 2)
    #expect(result.first?.longitude == coordinates.first?.longitude)
    #expect(result.last?.longitude == coordinates.last?.longitude)
  }

  @Test
  func endpointsAreAlwaysPreserved() {
    let coordinates = (0...50).map {
      CLLocationCoordinate2D(latitude: 51.5 + Double($0) * 0.0005, longitude: -0.1 + sin(Double($0)) * 0.001)
    }
    let result = PolylineSimplifier.simplify(coordinates, toleranceMeters: 10)
    #expect(result.first?.latitude == coordinates.first?.latitude)
    #expect(result.first?.longitude == coordinates.first?.longitude)
    #expect(result.last?.latitude == coordinates.last?.latitude)
    #expect(result.last?.longitude == coordinates.last?.longitude)
  }

  @Test
  func significantDeviationIsRetained() {
    // A straight line with one point pushed far off-axis (~100m) must keep that point.
    let coordinates = [
      CLLocationCoordinate2D(latitude: 51.5, longitude: -0.100),
      CLLocationCoordinate2D(latitude: 51.5 + 0.001, longitude: -0.105),
      CLLocationCoordinate2D(latitude: 51.5, longitude: -0.110)
    ]
    let result = PolylineSimplifier.simplify(coordinates, toleranceMeters: 5)
    #expect(result.count == 3)
  }

  @Test
  func simplificationNeverIncreasesPointCount() {
    let coordinates = (0...500).map {
      CLLocationCoordinate2D(latitude: 51.5 + Double($0) * 0.0001, longitude: -0.1 + Double($0) * 0.0001)
    }
    let result = PolylineSimplifier.simplify(coordinates, toleranceMeters: 5)
    #expect(result.count <= coordinates.count)
    #expect(result.count >= 2)
  }
}
