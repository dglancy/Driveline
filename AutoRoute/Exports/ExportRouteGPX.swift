//
//  ExportRouteServiceGPX.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import CoreLocation
import GPXKit
import os.log

// MARK: – GPX Export Service Errors

enum ExportRouteServiceGPXError: Error {
  case encodingFailed
}

// MARK: - GPX Export Service

final class ExportRouteGPX: ExportRouteBase {

  // MARK: - Lifecycle

  nonisolated override init() {
    super.init()
  }

  // MARK: - Computed properties

  private static func formattedStartedAt(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy'-'HHmm"
    formatter.timeZone = .current
    formatter.locale = .current
    return formatter.string(from: date)
  }

  // MARK: - Actions

  override func export(route: Route) async throws -> URL {
    _ = try coordinates(for: route)

    let track = try await buildTrack(from: route)
    let gpxExport = GPXExporter(track: track, shouldExportDate: true, creatorName: kGPXCreator).xmlString
    let fileURL = ExportRouteFileNamingService.fileURL(for: route, type: .gpx)

    guard let gpxExportData = gpxExport.data(using: .utf8) else {
      throw ExportRouteServiceGPXError.encodingFailed
    }

    try gpxExportData.write(to: fileURL, options: .atomic)
    return fileURL
  }

  // MARK: - Private

  func buildTrack(from route: Route) async throws -> GPXTrack {
    let trackPoints = try buildTrackPoints(from: route)
    let track = try GPXTrack(
      title: Self.formattedStartedAt(route.startedAt),
      trackPoints: trackPoints,
      keywords: [],
      elevationSmoothing: .none
    )
    return track
  }

  func buildTrackPoints(from route: Route) throws -> [TrackPoint] {
    return route.orderedPositions.map { position in
      TrackPoint(
        coordinate: Coordinate(latitude: position.latitude, longitude: position.longitude, elevation: position.altitude),
        date: position.timestamp,
        speed: Measurement(value: position.speed, unit: UnitSpeed.metersPerSecond)
      )
    }
  }
}
