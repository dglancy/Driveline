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

    let xml = xmlString(title: drive.displayName, positions: positions, drive: drive)
    let fileURL = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)

    guard let data = xml.data(using: .utf8) else {
      throw ExportError.gpxEncodingFailed
    }

    try data.write(to: fileURL, options: .atomic)
    return fileURL
  }

  // MARK: - Private

  private func xmlString(title: String, positions: [Position], drive: Drive) -> String {
    let iso = ISO8601DateFormatter()
    let trkpts = positions.map { pos in
      """
            <trkpt lat="\(pos.latitude)" lon="\(pos.longitude)">
              <ele>\(pos.altitude)</ele>
              <time>\(iso.string(from: pos.timestamp))</time>
              <extensions>
                <gpxtpx:TrackPointExtension>
                  <gpxtpx:speed>\(pos.speed)</gpxtpx:speed>
                </gpxtpx:TrackPointExtension>
              </extensions>
            </trkpt>
      """
    }.joined(separator: "\n")

    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:drv="https://www.targatrips.com/gpx/v1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" version="1.1" creator="\(Constants.App.GPXCreator)">
      <trk>
        <name>\(xmlEscaped(title))</name>
    \(statsExtensionXML(for: drive))
        <trkseg>
    \(trkpts)
        </trkseg>
      </trk>
    </gpx>
    """
  }

  private func statsExtensionXML(for drive: Drive) -> String {
    let kmh = Constants.Statistics.metresPerSecondToKilometresPerHour
    return """
          <extensions>
            <drv:stats>
              <drv:distanceMetres>\(number(drive.distanceMetres))</drv:distanceMetres>
              <drv:averageSpeedKmh>\(number(drive.avgSpeedMetresPerSecond * kmh))</drv:averageSpeedKmh>
              <drv:meanSpeedKmh>\(number(drive.meanSpeedMetresPerSecond * kmh))</drv:meanSpeedKmh>
              <drv:speedStandardDeviationKmh>\(number(drive.speedStandardDeviationMetresPerSecond * kmh))</drv:speedStandardDeviationKmh>
              <drv:speedVarianceKmh2>\(number(drive.speedVarianceMetresPerSecondSquared * kmh * kmh))</drv:speedVarianceKmh2>
              <drv:percentTimeAbove80Kmh>\(number(drive.fractionOfTimeAboveHighSpeed * 100))</drv:percentTimeAbove80Kmh>
              <drv:sustainedHighSpeedSegmentCount>\(drive.sustainedHighSpeedSegmentCount)</drv:sustainedHighSpeedSegmentCount>
              <drv:stopCount>\(drive.stopCount)</drv:stopCount>
              <drv:percentTimeStopped>\(number(drive.fractionOfTimeStopped * 100))</drv:percentTimeStopped>
              <drv:sinuosity>\(number(drive.sinuosity, decimals: 3))</drv:sinuosity>
              <drv:bearingChangeRateDegreesPerKilometre>\(number(drive.bearingChangeRateDegreesPerKilometre))</drv:bearingChangeRateDegreesPerKilometre>
              <drv:elevationGainMetres>\(number(drive.elevationGainMetres))</drv:elevationGainMetres>
              <drv:elevationLossMetres>\(number(drive.elevationLossMetres))</drv:elevationLossMetres>
            </drv:stats>
          </extensions>
    """
  }

  private func number(_ value: Double, decimals: Int = 1) -> String {
    String(format: "%.\(decimals)f", value)
  }

  private func xmlEscaped(_ string: String) -> String {
    string
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&apos;")
  }
}
