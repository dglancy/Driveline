//
//  ExportRouteFileNamingServiceTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import AutoRoutes
import Foundation
import Testing

@Suite("ExportRouteFileNamingService")
@MainActor
final class ExportRouteFileNamingServiceTests: SwiftDataBaseTestCase {

  // MARK: - File extension

  @Test
  func gpxFileURLHasCorrectExtension() {
    let url = ExportRouteFileNamingService.fileURL(for: makeRoute(), type: .gpx)
    #expect(url.pathExtension == "gpx")
  }

  @Test
  func pngFileURLHasCorrectExtension() {
    let url = ExportRouteFileNamingService.fileURL(for: makeRoute(), type: .png)
    #expect(url.pathExtension == "png")
  }

  // MARK: - Filename format

  @Test
  func filenamePrefixMatchesFormattedStartedAt() {
    let route = makeRoute()
    let expectedPrefix = ExportRouteFileNamingService.startedAtFormatter.string(from: route.startedAt)
    let url = ExportRouteFileNamingService.fileURL(for: route, type: .gpx)
    #expect(url.lastPathComponent.hasPrefix(expectedPrefix))
  }

  @Test
  func formatterProducesEnglishMonthAbbreviationRegardlessOfSystemLocale() {
    let route = makeRoute()
    let germanFormatter = DateFormatter()
    germanFormatter.dateFormat = "dd-MMM-yyyy'-'HHmm"
    germanFormatter.timeZone = .current
    germanFormatter.locale = Locale(identifier: "de_DE")
    #expect(germanFormatter.string(from: route.startedAt).contains("Mai"))
    let formatted = ExportRouteFileNamingService.startedAtFormatter.string(from: route.startedAt)
    #expect(formatted.contains("May"))
  }

  @Test
  func filenamesForSameRouteDifferOnlyByExtension() {
    let route = makeRoute()
    let gpxURL = ExportRouteFileNamingService.fileURL(for: route, type: .gpx)
    let pngURL = ExportRouteFileNamingService.fileURL(for: route, type: .png)
    #expect(gpxURL.deletingPathExtension().lastPathComponent == pngURL.deletingPathExtension().lastPathComponent)
  }

  // MARK: - Location

  @Test
  func fileURLIsInTemporaryDirectory() {
    let url = ExportRouteFileNamingService.fileURL(for: makeRoute(), type: .gpx)
    #expect(url.path.hasPrefix(FileManager.default.temporaryDirectory.path))
  }

  // MARK: - Helpers

  private func makeRoute() -> Route {
    let route = Route(name: "Test Route")
    var components = DateComponents()
    components.year = 2026
    components.month = 5
    components.day = 31
    components.hour = 10
    components.minute = 30
    components.timeZone = .current
    route.startedAt = Calendar.current.date(from: components) ?? .now
    return route
  }
}
