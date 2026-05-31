//
//  FullScreenMapViewModelTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

import Testing
import Foundation
import MapKit
import SwiftUI
@testable import AutoRoute

@Suite("FullScreenMapViewModel")
@MainActor
struct FullScreenMapViewModelTests {

  // MARK: - name

  @Test
  func nameReturnsRouteName() {
    let vm = FullScreenMapViewModel(route: makeRoute(name: "Morning Commute"))
    #expect(vm.name == "Morning Commute")
  }

  // MARK: - coordinates

  @Test
  func coordinatesAreEmptyWithNoPositions() {
    let vm = FullScreenMapViewModel(route: makeRoute())
    #expect(vm.coordinates.isEmpty)
  }

  @Test
  func coordinatesCountMatchesPositionCount() {
    let route = makeRoute()
    route.positions.append(makePosition(latitude: 37.0, longitude: -122.0))
    route.positions.append(makePosition(latitude: 38.0, longitude: -121.0))
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.coordinates.count == 2)
  }

  @Test
  func coordinatesPreserveLatitudeAndLongitude() {
    let route = makeRoute()
    route.positions.append(makePosition(latitude: 37.5, longitude: -122.4))
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.coordinates[0].latitude == 37.5)
    #expect(vm.coordinates[0].longitude == -122.4)
  }

  // MARK: - cameraPosition

  @Test
  func cameraPositionIsAutomaticWithNoPositions() {
    let vm = FullScreenMapViewModel(route: makeRoute())
    #expect(vm.cameraPosition == .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithSinglePosition() {
    let route = makeRoute()
    route.positions.append(makePosition(latitude: 37.0, longitude: -122.0))
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.cameraPosition != .automatic)
  }

  @Test
  func cameraPositionIsNotAutomaticWithMultiplePositions() {
    let route = makeRoute()
    route.positions.append(makePosition(latitude: 37.0, longitude: -122.0))
    route.positions.append(makePosition(latitude: 38.0, longitude: -121.0))
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.cameraPosition != .automatic)
  }

  // MARK: - distanceValue / distanceUnit

  @Test
  func distanceValueMatchesRouteFormatting() {
    let route = makeRoute()
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.distanceValue == route.distanceMetres.localizedDistanceValueString())
  }

  @Test
  func distanceUnitMatchesRouteFormatting() {
    let route = makeRoute()
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.distanceUnit == route.distanceMetres.localizedDistanceUnitSymbol())
  }

  // MARK: - durationValue

  @Test
  func durationValueMatchesRouteFormatting() {
    let route = makeRoute()
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.durationValue == route.activeDurationSeconds.localizedHoursMinutesString())
  }

  // MARK: - avgSpeedValue / avgSpeedUnit

  @Test
  func avgSpeedValueMatchesRouteFormatting() {
    let route = makeRoute()
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.avgSpeedValue == route.avgSpeedMetresPerSecond.localizedSpeedValueString())
  }

  @Test
  func avgSpeedUnitMatchesRouteFormatting() {
    let route = makeRoute()
    let vm = FullScreenMapViewModel(route: route)
    #expect(vm.avgSpeedUnit == route.avgSpeedMetresPerSecond.localizedSpeedUnitSymbol())
  }
}

// MARK: - Helpers

private func makeRoute(name: String = "Test Route") -> Route {
  Route(name: name)
}
