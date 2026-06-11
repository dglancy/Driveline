//
//  GPXStatisticsParser.swift
//  MLTrainingDataPrepTool
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation

// MARK: - Parsing errors

enum GPXParsingError: Error, LocalizedError, Equatable {
  case malformedXML
  case missingStatsBlock
  case missingField(String)

  // MARK: - LocalizedError

  var errorDescription: String? {
    switch self {
    case .malformedXML:
      return "The GPX file could not be parsed as XML."
    case .missingStatsBlock:
      return "The GPX file does not contain a <drv:stats> extension block."
    case .missingField(let name):
      return "The GPX file is missing the required field <\(name)>."
    }
  }
}

// MARK: - GPX statistics parser

final class GPXStatisticsParser: NSObject, XMLParserDelegate {

  // MARK: - Private Properties

  private var trackName: String?
  private var statValues: [String: String] = [:]
  private var currentValue = ""
  private var isInsideStats = false
  private var isInsideTrackName = false
  private var hasFoundStatsBlock = false
  private var hasFoundTrackName = false

  // MARK: - Actions

  func parse(data: Data) throws -> GPXDriveStatistics {
    let parser = XMLParser(data: data)
    parser.delegate = self

    guard parser.parse() else {
      throw GPXParsingError.malformedXML
    }
    guard hasFoundStatsBlock else {
      throw GPXParsingError.missingStatsBlock
    }

    return try makeStatistics()
  }

  // MARK: - XMLParserDelegate

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String] = [:]
  ) {
    currentValue = ""

    if elementName == "drv:stats" {
      isInsideStats = true
      hasFoundStatsBlock = true
    } else if elementName == "name" && !hasFoundTrackName {
      isInsideTrackName = true
    }
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    currentValue += string
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

    if elementName == "drv:stats" {
      isInsideStats = false
    } else if isInsideStats {
      statValues[elementName] = trimmedValue
    } else if elementName == "name" && isInsideTrackName {
      trackName = trimmedValue
      isInsideTrackName = false
      hasFoundTrackName = true
    }

    currentValue = ""
  }

  // MARK: - Private

  private func makeStatistics() throws -> GPXDriveStatistics {
    GPXDriveStatistics(
      name: trackName ?? "",
      distanceMetres: try doubleValue(for: "drv:distanceMetres"),
      durationSeconds: try intValue(for: "drv:durationSeconds"),
      averageSpeedKmh: try doubleValue(for: "drv:averageSpeedKmh"),
      meanSpeedKmh: try doubleValue(for: "drv:meanSpeedKmh"),
      speedStandardDeviationKmh: try doubleValue(for: "drv:speedStandardDeviationKmh"),
      speedVarianceKmh2: try doubleValue(for: "drv:speedVarianceKmh2"),
      percentTimeAbove80Kmh: try doubleValue(for: "drv:percentTimeAbove80Kmh"),
      sustainedHighSpeedSegmentCount: try intValue(for: "drv:sustainedHighSpeedSegmentCount"),
      stopCount: try intValue(for: "drv:stopCount"),
      percentTimeStopped: try doubleValue(for: "drv:percentTimeStopped"),
      sinuosity: try doubleValue(for: "drv:sinuosity"),
      bearingChangeRateDegreesPerKilometre: try doubleValue(for: "drv:bearingChangeRateDegreesPerKilometre"),
      elevationGainMetres: try doubleValue(for: "drv:elevationGainMetres"),
      elevationLossMetres: try doubleValue(for: "drv:elevationLossMetres")
    )
  }

  private func doubleValue(for key: String) throws -> Double {
    guard let raw = statValues[key], let value = Double(raw) else {
      throw GPXParsingError.missingField(key)
    }
    return value
  }

  private func intValue(for key: String) throws -> Int {
    guard let raw = statValues[key], let value = Int(raw) else {
      throw GPXParsingError.missingField(key)
    }
    return value
  }
}
