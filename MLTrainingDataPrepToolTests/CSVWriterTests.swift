//
//  CSVWriterTests.swift
//  MLTrainingDataPrepToolTests
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation
import Testing

@Suite("CSVWriter")
struct CSVWriterTests {

  // MARK: - Header creation

  @Test
  func createsFileWithHeaderWhenFileDoesNotExist() throws {
    let url = makeTemporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }

    try CSVWriter.append([sampleStatistics()], to: url)

    let content = try String(contentsOf: url, encoding: .utf8)
    let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(lines[0] == CSVWriter.header)
    #expect(lines.count == 3) // header + 1 row + trailing empty
  }

  // MARK: - Appending

  @Test
  func appendsWithoutDuplicatingHeaderOnExistingFile() throws {
    let url = makeTemporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }

    try CSVWriter.append([sampleStatistics()], to: url)
    try CSVWriter.append([sampleStatistics()], to: url)

    let content = try String(contentsOf: url, encoding: .utf8)
    let headerOccurrences = content.components(separatedBy: CSVWriter.header).count - 1
    #expect(headerOccurrences == 1)

    let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    #expect(lines.count == 4) // header + 2 rows + trailing empty
  }

  // MARK: - Escaping

  @Test
  func escapesNameContainingComma() {
    let statistics = sampleStatistics(name: "Ashtown, Dublin 15 → Castleknock, Dublin 15")

    let row = CSVWriter.row(for: statistics)

    #expect(row.hasPrefix("\"Ashtown, Dublin 15 → Castleknock, Dublin 15\","))
  }

  @Test
  func escapesNameContainingNewline() {
    let statistics = sampleStatistics(name: "Multi\nLine")

    let row = CSVWriter.row(for: statistics)

    #expect(row.hasPrefix("\"Multi\nLine\","))
  }

  @Test
  func doesNotEscapeNameWithoutSpecialCharacters() {
    let statistics = sampleStatistics(name: "Simple Drive")

    let row = CSVWriter.row(for: statistics)

    #expect(row.hasPrefix("Simple Drive,"))
  }

  // MARK: - Category

  @Test
  func headerEndsWithCategoryColumn() {
    #expect(CSVWriter.header.hasSuffix(",Category"))
  }

  @Test
  func rowEndsWithEmptyCategoryField() {
    let row = CSVWriter.row(for: sampleStatistics())

    #expect(row.hasSuffix(","))
  }

  // MARK: - Helpers

  private func makeTemporaryURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
  }

  private func sampleStatistics(name: String = "Test Drive") -> GPXDriveStatistics {
    GPXDriveStatistics(
      name: name,
      distanceMetres: 11917.1,
      durationSeconds: 1800,
      averageSpeedKmh: 7.9,
      meanSpeedKmh: 9.3,
      speedStandardDeviationKmh: 15.9,
      speedVarianceKmh2: 253.4,
      percentTimeAbove80Kmh: 0.0,
      sustainedHighSpeedSegmentCount: 0,
      stopCount: 18,
      percentTimeStopped: 56.7,
      sinuosity: 268.98,
      bearingChangeRateDegreesPerKilometre: 3853.8,
      elevationGainMetres: 194.7,
      elevationLossMetres: 205.1
    )
  }
}
