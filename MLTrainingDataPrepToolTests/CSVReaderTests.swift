//
//  CSVReaderTests.swift
//  MLTrainingDataPrepToolTests
//
//  Created by Damien Glancy on 12/06/2026.
//

import Foundation
import Testing

@Suite("CSVReader")
struct CSVReaderTests {

  // MARK: - Existing names

  @Test
  func returnsEmptySetWhenFileDoesNotExist() throws {
    let url = makeTemporaryURL()

    let names = try CSVReader.existingNames(at: url)

    #expect(names.isEmpty)
  }

  @Test
  func returnsNamesFromExistingFileExcludingHeader() throws {
    let url = makeTemporaryURL()
    defer { try? FileManager.default.removeItem(at: url) }

    let content = "\(CSVWriter.header)\nDrive One,1,2,3\nDrive Two,4,5,6\n"
    try content.write(to: url, atomically: true, encoding: .utf8)

    let names = try CSVReader.existingNames(at: url)

    #expect(names == ["Drive One", "Drive Two"])
  }

  // MARK: - Row parsing

  @Test
  func parsesQuotedFieldContainingComma() {
    let rows = CSVReader.parseRows(from: "\"Ashtown, Dublin 15\",1,2\n")

    #expect(rows == [["Ashtown, Dublin 15", "1", "2"]])
  }

  @Test
  func parsesQuotedFieldContainingNewline() {
    let rows = CSVReader.parseRows(from: "\"Multi\nLine\",1,2\n")

    #expect(rows == [["Multi\nLine", "1", "2"]])
  }

  @Test
  func parsesQuotedFieldContainingEscapedQuote() {
    let rows = CSVReader.parseRows(from: "\"Say \"\"Hello\"\"\",1,2\n")

    #expect(rows == [["Say \"Hello\"", "1", "2"]])
  }

  // MARK: - Helpers

  private func makeTemporaryURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).csv")
  }
}
