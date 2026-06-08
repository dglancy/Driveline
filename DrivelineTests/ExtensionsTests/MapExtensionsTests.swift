//
//  MapExtensionsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 08/06/2026.
//

@testable import Driveline
import CoreLocation
import MapKit
import SwiftUI
import Testing

// MARK: - MKCoordinateRegion.boundingBox

@Suite("MKCoordinateRegion.boundingBox")
struct MKCoordinateRegionBoundingBoxTests {

  @Test
  func returnsNilForEmptyArray() {
    #expect(MKCoordinateRegion.boundingBox(of: []) == nil)
  }

  @Test
  func returnsNonNilForSingleCoordinate() {
    let coord = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
    #expect(MKCoordinateRegion.boundingBox(of: [coord]) != nil)
  }

  @Test
  func singleCoordinateCenterMatchesInput() {
    let coord = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
    let region = MKCoordinateRegion.boundingBox(of: [coord])!
    #expect(region.center.latitude == 51.5)
    #expect(region.center.longitude == -0.1)
  }

  @Test
  func singleCoordinateHasZeroSpan() {
    let coord = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
    let region = MKCoordinateRegion.boundingBox(of: [coord])!
    #expect(region.span.latitudeDelta == 0)
    #expect(region.span.longitudeDelta == 0)
  }

  @Test
  func twoCoordinatesCenterIsMidpoint() {
    let a = CLLocationCoordinate2D(latitude: 50.0, longitude: -1.0)
    let b = CLLocationCoordinate2D(latitude: 52.0, longitude: 1.0)
    let region = MKCoordinateRegion.boundingBox(of: [a, b])!
    #expect(region.center.latitude == 51.0)
    #expect(region.center.longitude == 0.0)
  }

  @Test
  func twoCoordinatesSpanCoversBothPoints() {
    let a = CLLocationCoordinate2D(latitude: 50.0, longitude: -1.0)
    let b = CLLocationCoordinate2D(latitude: 52.0, longitude: 1.0)
    let region = MKCoordinateRegion.boundingBox(of: [a, b])!
    #expect(region.span.latitudeDelta == 2.0)
    #expect(region.span.longitudeDelta == 2.0)
  }

  @Test
  func multipleCoordinatesCenterIsCorrect() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0),
      CLLocationCoordinate2D(latitude: 53.0, longitude: 0.0),
      CLLocationCoordinate2D(latitude: 52.0, longitude: 1.0)
    ]
    let region = MKCoordinateRegion.boundingBox(of: coords)!
    #expect(abs(region.center.latitude - 52.0) < 0.0001)
    #expect(abs(region.center.longitude - 0.0) < 0.0001)
  }

  @Test
  func multipleCoordinatesSpanCoversExtremes() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0),
      CLLocationCoordinate2D(latitude: 53.0, longitude: 0.0),
      CLLocationCoordinate2D(latitude: 52.0, longitude: 1.0)
    ]
    let region = MKCoordinateRegion.boundingBox(of: coords)!
    #expect(region.span.latitudeDelta == 2.0)
    #expect(region.span.longitudeDelta == 2.0)
  }
}

// MARK: - MKCoordinateRegion.fitting

@Suite("MKCoordinateRegion.fitting")
struct MKCoordinateRegionFittingTests {

  @Test
  func emptyArrayReturnsDefaultRegion() {
    let region = MKCoordinateRegion.fitting([])
    #expect(region.center.latitude == 0.0)
    #expect(region.center.longitude == 0.0)
  }

  @Test
  func singlePointCenterIsPreserved() {
    let coord = CLLocationCoordinate2D(latitude: 37.5, longitude: -122.4)
    let region = MKCoordinateRegion.fitting([coord])
    #expect(abs(region.center.latitude - 37.5) < 0.0001)
    #expect(abs(region.center.longitude - (-122.4)) < 0.0001)
  }

  @Test
  func singlePointSpanRespectsMinimumSpan() {
    let coord = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
    let minimumSpan = 0.005
    let region = MKCoordinateRegion.fitting([coord], minimumSpan: minimumSpan)
    #expect(region.span.latitudeDelta >= minimumSpan)
    #expect(region.span.longitudeDelta >= minimumSpan)
  }

  @Test
  func largePaddingMultiplierProducesLargerSpanThanSmall() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0),
      CLLocationCoordinate2D(latitude: 52.0, longitude: 0.0)
    ]
    let small = MKCoordinateRegion.fitting(coords, paddingMultiplier: 1.0)
    let large = MKCoordinateRegion.fitting(coords, paddingMultiplier: 3.0)
    #expect(large.span.latitudeDelta > small.span.latitudeDelta)
  }

  @Test
  func closeCoordinatesStillRespectMinimumSpan() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.5000, longitude: -0.1000),
      CLLocationCoordinate2D(latitude: 51.5001, longitude: -0.1001)
    ]
    let minimumSpan = 0.1
    let region = MKCoordinateRegion.fitting(coords, minimumSpan: minimumSpan)
    #expect(region.span.latitudeDelta >= minimumSpan)
    #expect(region.span.longitudeDelta >= minimumSpan)
  }

  @Test
  func spanIsPositiveForNonEmptyCoordinates() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0),
      CLLocationCoordinate2D(latitude: 52.0, longitude: 0.0)
    ]
    let region = MKCoordinateRegion.fitting(coords)
    #expect(region.span.latitudeDelta > 0)
    #expect(region.span.longitudeDelta > 0)
  }
}

// MARK: - MapCameraPosition.fit

@Suite("MapCameraPosition.fit")
@MainActor
struct MapCameraPositionFitTests {

  @Test
  func returnsAutomaticForEmptyCoordinates() {
    #expect(MapCameraPosition.fit(to: []) == .automatic)
  }

  @Test
  func returnsNonAutomaticForSingleCoordinate() {
    let coord = CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1)
    #expect(MapCameraPosition.fit(to: [coord]) != .automatic)
  }

  @Test
  func returnsNonAutomaticForMultipleCoordinates() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0),
      CLLocationCoordinate2D(latitude: 52.0, longitude: 0.0)
    ]
    #expect(MapCameraPosition.fit(to: coords) != .automatic)
  }

  @Test
  func differentPaddingMultipliersProduceDifferentResults() {
    let coords = [
      CLLocationCoordinate2D(latitude: 51.0, longitude: -1.0),
      CLLocationCoordinate2D(latitude: 52.0, longitude: 0.0)
    ]
    let small = MapCameraPosition.fit(to: coords, paddingMultiplier: 1.0)
    let large = MapCameraPosition.fit(to: coords, paddingMultiplier: 3.0)
    #expect(small != large)
  }
}
