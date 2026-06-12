//
//  MLTrainingDataPrepToolTests.swift
//  MLTrainingDataPrepToolTests
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation
import Testing

@Suite("MLTrainingDataPrepTool")
struct MLTrainingDataPrepToolTests {

  // MARK: - End to end

  @Test
  func writesOneRowPerGPXFile() throws {
    let inputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: inputDirectory) }

    try Self.gpx(name: "Drive One").write(
      to: inputDirectory.appendingPathComponent("a.gpx"),
      atomically: true,
      encoding: .utf8
    )
    try Self.gpx(name: "Drive Two").write(
      to: inputDirectory.appendingPathComponent("b.gpx"),
      atomically: true,
      encoding: .utf8
    )

    let outputCSV = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
    defer { try? FileManager.default.removeItem(at: outputCSV) }

    let command = try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path])
    try command.run()

    let content = try String(contentsOf: outputCSV, encoding: .utf8)
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(lines[0] == CSVWriter.header)
    #expect(lines[1].hasPrefix("Drive One,"))
    #expect(lines[2].hasPrefix("Drive Two,"))
  }

  @Test
  func throwsWhenInputDirectoryDoesNotExist() throws {
    let missingDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let outputCSV = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")

    let command = try MLTrainingDataPrepTool.parse([missingDirectory.path, outputCSV.path])

    #expect(throws: MLTrainingDataPrepToolError.inputDirectoryNotFound(missingDirectory.path)) {
      try command.run()
    }
  }

  @Test
  func throwsWhenNoGPXFilesFound() throws {
    let inputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: inputDirectory) }

    let outputCSV = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")

    let command = try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path])

    #expect(throws: MLTrainingDataPrepToolError.noGPXFilesFound(inputDirectory.path)) {
      try command.run()
    }
  }

  @Test
  func skipsFilesThatFailToParseAndContinuesWithRemaining() throws {
    let inputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: inputDirectory) }

    try "not xml".write(
      to: inputDirectory.appendingPathComponent("a.gpx"),
      atomically: true,
      encoding: .utf8
    )
    try Self.gpx(name: "Drive Two").write(
      to: inputDirectory.appendingPathComponent("b.gpx"),
      atomically: true,
      encoding: .utf8
    )

    let outputCSV = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
    defer { try? FileManager.default.removeItem(at: outputCSV) }

    let command = try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path])
    try command.run()

    let content = try String(contentsOf: outputCSV, encoding: .utf8)
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(lines[0] == CSVWriter.header)
    #expect(lines[1].hasPrefix("Drive Two,"))
    #expect(lines.count == 3) // header + 1 row + trailing empty
  }

  // MARK: - Deduplication

  @Test
  func doesNotDuplicateRowsWhenRunTwiceOverSameInput() throws {
    let inputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: inputDirectory) }

    try Self.gpx(name: "Drive One").write(
      to: inputDirectory.appendingPathComponent("a.gpx"),
      atomically: true,
      encoding: .utf8
    )
    try Self.gpx(name: "Drive Two").write(
      to: inputDirectory.appendingPathComponent("b.gpx"),
      atomically: true,
      encoding: .utf8
    )

    let outputCSV = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
    defer { try? FileManager.default.removeItem(at: outputCSV) }

    try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path]).run()
    try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path]).run()

    let content = try String(contentsOf: outputCSV, encoding: .utf8)
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(lines.count == 4) // header + 2 rows + trailing empty
  }

  @Test
  func preservesHumanEnteredCategoryOnRerun() throws {
    let inputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: inputDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: inputDirectory) }

    try Self.gpx(name: "Drive One").write(
      to: inputDirectory.appendingPathComponent("a.gpx"),
      atomically: true,
      encoding: .utf8
    )

    let outputCSV = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
    defer { try? FileManager.default.removeItem(at: outputCSV) }

    try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path]).run()

    var content = try String(contentsOf: outputCSV, encoding: .utf8)
    var lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    lines[1] += "Commute"
    try lines.joined(separator: "\n").write(to: outputCSV, atomically: true, encoding: .utf8)

    try MLTrainingDataPrepTool.parse([inputDirectory.path, outputCSV.path]).run()

    content = try String(contentsOf: outputCSV, encoding: .utf8)
    lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(lines.count == 3) // header + 1 row + trailing empty
    #expect(lines[1].hasSuffix(",Commute"))
  }

  // MARK: - Fixtures

  private static func gpx(name: String) -> String {
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:drv="https://www.targatrips.com/gpx/v1" version="1.1" creator="Driveline for iOS">
      <trk>
        <name>\(name)</name>
        <extensions>
          <drv:stats>
            <drv:distanceMetres>11917.1</drv:distanceMetres>
            <drv:durationSeconds>1800</drv:durationSeconds>
            <drv:averageSpeedKmh>7.9</drv:averageSpeedKmh>
            <drv:meanSpeedKmh>9.3</drv:meanSpeedKmh>
            <drv:speedStandardDeviationKmh>15.9</drv:speedStandardDeviationKmh>
            <drv:speedVarianceKmh2>253.4</drv:speedVarianceKmh2>
            <drv:percentTimeAbove80Kmh>0.0</drv:percentTimeAbove80Kmh>
            <drv:sustainedHighSpeedSegmentCount>0</drv:sustainedHighSpeedSegmentCount>
            <drv:stopCount>18</drv:stopCount>
            <drv:percentTimeStopped>56.7</drv:percentTimeStopped>
            <drv:sinuosity>268.980</drv:sinuosity>
            <drv:bearingChangeRateDegreesPerKilometre>3853.8</drv:bearingChangeRateDegreesPerKilometre>
            <drv:elevationGainMetres>194.7</drv:elevationGainMetres>
            <drv:elevationLossMetres>205.1</drv:elevationLossMetres>
          </drv:stats>
        </extensions>
        <trkseg>
          <trkpt lat="53.0" lon="-6.0">
            <ele>10.0</ele>
            <time>2026-06-11T12:01:55Z</time>
          </trkpt>
        </trkseg>
      </trk>
    </gpx>
    """
  }
}
