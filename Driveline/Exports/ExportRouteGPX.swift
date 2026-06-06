//
//  ExportDriveGPX.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation

// MARK: - GPX export service

final class ExportDriveGPX: ExportingDrive {

  // MARK: - Actions

  func export(drive: Drive) async throws -> URL {
    let positions = drive.orderedPositions
    guard !positions.isEmpty else { throw ExportError.emptyDrive }

    let title = ExportDriveFileNamingService.startedAtFormatter.string(from: drive.startedAt)
    let xml = xmlString(title: title, positions: positions)
    let fileURL = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)

    guard let data = xml.data(using: .utf8) else {
      throw ExportError.gpxEncodingFailed
    }

    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }

  // MARK: - Private

  private func xmlString(title: String, positions: [Position]) -> String {
    let iso = ISO8601DateFormatter()
    let trkpts = positions.map { pos in
      """
            <trkpt lat="\(pos.latitude)" lon="\(pos.longitude)">
              <ele>\(pos.altitude)</ele>
              <time>\(iso.string(from: pos.timestamp))</time>
              <extensions><speed>\(pos.speed)</speed></extensions>
            </trkpt>
      """
    }.joined(separator: "\n")

    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="\(kGPXCreator)">
      <trk>
        <name>\(title)</name>
        <trkseg>
    \(trkpts)
        </trkseg>
      </trk>
    </gpx>
    """
  }
}
