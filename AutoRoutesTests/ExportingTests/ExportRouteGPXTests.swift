//
//  ExportRouteGPXTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import AutoRoutes
import Foundation
import Testing

@Suite("ExportRouteGPX")
@MainActor
final class ExportRouteGPXTests: SwiftDataBaseTestCase {

  // MARK: - Error descriptions

  @Test
  func emptyRouteErrorHasUserFacingDescription() {
    #expect(ExportError.emptyRoute.errorDescription != nil)
    #expect(ExportError.emptyRoute.errorDescription?.isEmpty == false)
  }

  @Test
  func encodingFailedErrorHasUserFacingDescription() {
    #expect(ExportError.gpxEncodingFailed.errorDescription != nil)
    #expect(ExportError.gpxEncodingFailed.errorDescription?.isEmpty == false)
  }

  // MARK: - Empty route

  @Test
  func throwsEmptyRouteErrorWhenRouteHasNoPositions() async {
    let route = Route(name: "Empty Route")

    await #expect(throws: ExportError.emptyRoute) {
      _ = try await ExportRouteGPX().export(route: route)
    }
  }

  // MARK: - File creation

  @Test
  func createsGPXFileAtReturnedURL() async throws {
    let route = routeWithOnePosition()

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    #expect(FileManager.default.fileExists(atPath: outputURL.path))
  }

  @Test
  func gpxFileIsNonEmpty() async throws {
    let route = routeWithOnePosition()

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let data = try Data(contentsOf: outputURL)
    #expect(!data.isEmpty)
  }

  @Test
  func gpxFileIsValidXML() async throws {
    let route = routeWithOnePosition()

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.hasPrefix("<?xml"))
  }

  @Test
  func gpxFileContainsTrackPointElements() async throws {
    let route = routeWithOnePosition()

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("trkpt"))
  }

  @Test
  func gpxFileContainsExpectedCoordinates() async throws {
    let route = Route(name: "Coordinate Test")
    let position = Position(
      timestamp: .now,
      latitude: 53.3498,
      longitude: -6.2603,
      altitude: 20,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 90,
      courseAccuracy: 5,
      speed: 8,
      speedAccuracy: 1
    )
    route.positions.append(position)

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("53.3498"))
    #expect(content.contains("-6.2603"))
  }

  @Test
  func gpxFilePreservesAllPositions() async throws {
    let route = Route(name: "Multi-point")
    let base = Date(timeIntervalSinceReferenceDate: 0)
    for i in 0..<5 {
      let position = Position(
        timestamp: base.addingTimeInterval(Double(i)),
        latitude: 51.5 + Double(i) * 0.001,
        longitude: -0.1,
        altitude: 10,
        horizontalAccuracy: 5,
        verticalAccuracy: 3,
        course: 0,
        courseAccuracy: 5,
        speed: 10,
        speedAccuracy: 1
      )
      route.positions.append(position)
    }

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    let trkptCount = content.components(separatedBy: "trkpt").count - 1
    #expect(trkptCount == 10) // 5 open + 5 close tags
  }

  @Test
  func gpxURLExtensionIsGpx() async throws {
    let route = routeWithOnePosition()

    let outputURL = try await ExportRouteGPX().export(route: route)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    #expect(outputURL.pathExtension == "gpx")
  }

  @Test
  func subsequentExportsOverwritePreviousFile() async throws {
    let route = routeWithOnePosition()
    let service = ExportRouteGPX()

    let firstURL = try await service.export(route: route)
    let secondURL = try await service.export(route: route)
    defer {
      try? FileManager.default.removeItem(at: firstURL)
    }

    #expect(firstURL == secondURL)
    #expect(FileManager.default.fileExists(atPath: secondURL.path))
  }

  // MARK: - Helpers

  private func routeWithOnePosition() -> Route {
    let route = Route(name: "Test Route")
    let position = Position(
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
    route.positions.append(position)
    return route
  }
}
