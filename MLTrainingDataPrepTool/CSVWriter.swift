//
//  CSVWriter.swift
//  MLTrainingDataPrepTool
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation

// MARK: - CSV writer

enum CSVWriter {

  // MARK: - Constants

  static let header = [
    "Name",
    "Distance",
    "Duration",
    "Average Speed",
    "Mean Speed",
    "Std Deviation Speed",
    "Speed Variance",
    "Percentage Time At High Speed",
    "Sustained High Speed Segment Count",
    "Stop Count",
    "Percentage Time Stopped",
    "Sinuosity",
    "Bearing Change Rate",
    "Elevation Gain",
    "Elevation Loss",
    "Category"
  ].joined(separator: ",")

  // MARK: - Actions

  static func append(_ records: [GPXDriveStatistics], to url: URL) throws {
    let fileExists = FileManager.default.fileExists(atPath: url.path)

    var lines: [String] = []
    if !fileExists {
      lines.append(header)
    }
    lines.append(contentsOf: records.map(row(for:)))

    let output = lines.map { $0 + "\n" }.joined()
    guard let data = output.data(using: .utf8) else {
      throw MLTrainingDataPrepToolError.csvEncodingFailed
    }

    if fileExists {
      let handle = try FileHandle(forWritingTo: url)
      defer { try? handle.close() }
      try handle.seekToEnd()
      try handle.write(contentsOf: data)
    } else {
      try data.write(to: url)
    }
  }

  static func row(for statistics: GPXDriveStatistics) -> String {
    let fields: [String] = [
      escaped(statistics.name),
      String(statistics.distanceMetres),
      String(statistics.durationSeconds),
      String(statistics.averageSpeedKmh),
      String(statistics.meanSpeedKmh),
      String(statistics.speedStandardDeviationKmh),
      String(statistics.speedVarianceKmh2),
      String(statistics.percentTimeAbove80Kmh),
      String(statistics.sustainedHighSpeedSegmentCount),
      String(statistics.stopCount),
      String(statistics.percentTimeStopped),
      String(statistics.sinuosity),
      String(statistics.bearingChangeRateDegreesPerKilometre),
      String(statistics.elevationGainMetres),
      String(statistics.elevationLossMetres),
      escaped(statistics.category)
    ]
    return fields.joined(separator: ",")
  }

  // MARK: - Private

  private static func escaped(_ field: String) -> String {
    guard field.contains(",") || field.contains("\"") || field.contains("\n") else {
      return field
    }

    let escapedQuotes = field.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escapedQuotes)\""
  }
}
