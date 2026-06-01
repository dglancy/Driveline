//
//  ExportRouteGPX.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import CoreLocation
import GPXKit

// MARK: - GPX export service

final class ExportRouteGPX: ExportingRoute {

  // MARK: - Actions

  func export(route: Route) async throws -> URL {
    let positions = route.orderedPositions
    guard !positions.isEmpty else { throw ExportError.emptyRoute }

    let track = try buildTrack(positions: positions, startedAt: route.startedAt)
    let gpxExport = GPXExporter(track: track, shouldExportDate: true, creatorName: kGPXCreator).xmlString
    let fileURL = ExportRouteFileNamingService.fileURL(for: route, type: .gpx)

    guard let gpxExportData = gpxExport.data(using: .utf8) else {
      throw ExportError.gpxEncodingFailed
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
