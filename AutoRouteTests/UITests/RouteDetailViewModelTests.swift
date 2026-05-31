//
//  RouteDetailViewModelTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import AutoRoute
import Foundation
import Testing

@Suite("RouteDetailViewModel")
@MainActor
struct RouteDetailViewModelTests {

  // MARK: - Initial State

  @Test
  func showSharingDialogIsFalseByDefault() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.showSharingDialog == false)
  }

  @Test
  func showingFullScreenMapIsFalseByDefault() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.showingFullScreenMap == false)
  }

  @Test
  func exportedFileIsNilByDefault() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.exportedFile == nil)
  }

  @Test
  func exportErrorIsNilByDefault() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.exportError == nil)
  }

  // MARK: - Computed Properties

  @Test
  func nameReturnsRouteName() {
    let vm = RouteDetailViewModel(route: makeRoute(name: "Dublin to Cork"))
    #expect(vm.name == "Dublin to Cork")
  }

  @Test
  func startPlaceReturnsRouteStartPlaceName() {
    let route = makeRoute()
    route.startPlaceName = "Home"
    let vm = RouteDetailViewModel(route: route)
    #expect(vm.startPlace == "Home")
  }

  @Test
  func endPlaceReturnsRouteEndPlaceName() {
    let route = makeRoute()
    route.endPlaceName = "Office"
    let vm = RouteDetailViewModel(route: route)
    #expect(vm.endPlace == "Office")
  }

  @Test
  func startPlaceIsNilWhenNotSet() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.startPlace == nil)
  }

  @Test
  func endPlaceIsNilWhenNotSet() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.endPlace == nil)
  }

  @Test
  func arrivalTimeIsNilWhenRouteHasNoEndDate() {
    let route = makeRoute()
    route.endedAt = nil
    let vm = RouteDetailViewModel(route: route)
    #expect(vm.arrivalTime == nil)
  }

  @Test
  func arrivalTimeIsNonNilWhenRouteHasEndDate() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.arrivalTime != nil)
  }

  @Test
  func trackPointsReflectsZeroPositionCount() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.trackPoints == "0")
  }

  @Test
  func triggerDisplayNameMatchesRouteTrigger() {
    let vm = RouteDetailViewModel(route: makeRoute())
    #expect(vm.triggerDisplayName == Route.RecordingTrigger.manual.displayName)
  }

  // MARK: - shareRouteGPX

  @Test
  func shareRouteGPXWithEmptyRouteSetsExportError() async {
    let vm = RouteDetailViewModel(route: makeRoute())
    vm.shareRouteGPX()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportError != nil)
  }

  @Test
  func shareRouteGPXWithEmptyRouteDoesNotSetExportedFile() async {
    let vm = RouteDetailViewModel(route: makeRoute())
    vm.shareRouteGPX()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportedFile == nil)
  }

  @Test
  func shareRouteGPXWithPositionsSetsExportedFile() async throws {
    let vm = RouteDetailViewModel(route: routeWithOnePosition())
    vm.shareRouteGPX()
    for _ in 0..<20 { await Task.yield() }
    let file = try #require(vm.exportedFile)
    defer { try? FileManager.default.removeItem(at: file.url) }
    #expect(vm.exportError == nil)
    #expect(file.url.pathExtension == "gpx")
    #expect(FileManager.default.fileExists(atPath: file.url.path))
  }

  // MARK: - shareRoutePNG

  @Test
  func shareRoutePNGWithEmptyRouteSetsExportError() async {
    let vm = RouteDetailViewModel(route: makeRoute())
    vm.shareRoutePNG()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportError != nil)
  }

  @Test
  func shareRoutePNGWithEmptyRouteDoesNotSetExportedFile() async {
    let vm = RouteDetailViewModel(route: makeRoute())
    vm.shareRoutePNG()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportedFile == nil)
  }

  // MARK: - ExportedFile

  @Test
  func exportedFileHasUniqueIDs() {
    let url = URL(fileURLWithPath: "/tmp/test.gpx")
    let a = ExportedFile(url: url)
    let b = ExportedFile(url: url)
    #expect(a.id != b.id)
  }

  @Test
  func exportedFileStoresURL() {
    let url = URL(fileURLWithPath: "/tmp/test.gpx")
    let file = ExportedFile(url: url)
    #expect(file.url == url)
  }

  // MARK: - Helpers

  private func makeRoute(name: String = "Test Route") -> Route {
    let route = Route(name: name)
    route.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    route.endedAt = Date(timeIntervalSinceReferenceDate: 3600)
    return route
  }

  private func routeWithOnePosition() -> Route {
    let route = makeRoute()
    route.positions.append(
      Position(
        latitude: 51.5074,
        longitude: -0.1278,
        altitude: 11,
        horizontalAccuracy: 5,
        verticalAccuracy: 3,
        course: 270,
        courseAccuracy: 5,
        speed: 14,
        speedAccuracy: 1
      )
    )
    return route
  }
}
