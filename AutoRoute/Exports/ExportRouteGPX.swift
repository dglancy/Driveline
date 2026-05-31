//
//  ExportRouteGPX.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import CoreLocation
import GPXKit
import os.log

// MARK: - GPX export error

enum ExportRouteGPXError: LocalizedError {
  case encodingFailed

  var errorDescription: String? {
    switch self {
    case .encodingFailed:
      return String(localized: "Failed to prepare GPX data for sharing.", comment: "Export error: GPX string could not be encoded as UTF-8")
    }
  }
}

// MARK: - GPX export service

final class ExportRouteGPX: ExportingRoute {

  // MARK: - Actions

  func export(route: Route) async throws -> URL {
    let positions = route.orderedPositions
    guard !positions.isEmpty else { throw ExportRouteError.emptyRoute }

    let track = try buildTrack(positions: positions, startedAt: route.startedAt)
    let gpxExport = GPXExporter(track: track, shouldExportDate: true, creatorName: kGPXCreator).xmlString
    let fileURL = ExportRouteFileNamingService.fileURL(for: route, type: .gpx)

    guard let gpxExportData = gpxExport.data(using: .utf8) else {
      throw ExportRouteGPXError.encodingFailed
    }

    try gpxExportData.write(to: fileURL, options: .atomic)
    return fileURL
  }

  // MARK: - Private

  private func buildTrack(positions: [Position], startedAt: Date) throws -> GPXTrack {
    let trackPoints = buildTrackPoints(from: positions)
    return try GPXTrack(
      title: ExportRouteFileNamingService.startedAtFormatter.string(from: startedAt),
      trackPoints: trackPoints,
      keywords: [],
      elevationSmoothing: .none
    )
  }

  private func buildTrackPoints(from positions: [Position]) -> [TrackPoint] {
    positions.map { position in
      TrackPoint(
        coordinate: Coordinate(latitude: position.latitude, longitude: position.longitude, elevation: position.altitude),
        date: position.timestamp,
        speed: Measurement(value: position.speed, unit: UnitSpeed.metersPerSecond)
      )
    }
  }
}
