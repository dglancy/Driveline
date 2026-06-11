//
//  ExportDriveGPXTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("ExportDriveGPX")
@MainActor
final class ExportDriveGPXTests: SwiftDataBaseTestCase {

  // MARK: - Error descriptions

  @Test
  func emptyDriveErrorHasUserFacingDescription() {
    #expect(ExportError.emptyDrive.errorDescription != nil)
    #expect(ExportError.emptyDrive.errorDescription?.isEmpty == false)
  }

  @Test
  func encodingFailedErrorHasUserFacingDescription() {
    #expect(ExportError.gpxEncodingFailed.errorDescription != nil)
    #expect(ExportError.gpxEncodingFailed.errorDescription?.isEmpty == false)
  }

  // MARK: - Empty drive

  @Test
  func throwsEmptyDriveErrorWhenDriveHasNoPositions() async {
    let drive = Drive(name: "Empty Drive")

    await #expect(throws: ExportError.emptyDrive) {
      _ = try await ExportDriveGPX().export(drive: drive)
    }
  }

  // MARK: - File creation

  @Test
  func createsGPXFileAtReturnedURL() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    #expect(FileManager.default.fileExists(atPath: outputURL.path))
  }

  @Test
  func gpxFileIsNonEmpty() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let data = try Data(contentsOf: outputURL)
    #expect(!data.isEmpty)
  }

  @Test
  func gpxFileIsValidXML() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.hasPrefix("<?xml"))
  }

  @Test
  func gpxFileContainsTrackPointElements() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("trkpt"))
  }

  @Test
  func gpxFileContainsExpectedCoordinates() async throws {
    let drive = Drive(name: "Coordinate Test")
    let position = Position(
      timestamp: .now,
      latitude: 53.3498,
      longitude: -6.2603,
      altitude: 20,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 90,
      courseAccuracy: 5,
      speed: 8,
      speedAccuracy: 1
    )
    drive.positions = (drive.positions ?? []) + [position]

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("53.3498"))
    #expect(content.contains("-6.2603"))
  }

  @Test
  func gpxFilePreservesAllPositions() async throws {
    let drive = Drive(name: "Multi-point")
    let base = Date(timeIntervalSinceReferenceDate: 0)
    for i in 0..<5 {
      let position = Position(
        timestamp: base.addingTimeInterval(Double(i)),
        latitude: 51.5 + Double(i) * 0.001,
        longitude: -0.1,
        altitude: 10,
        horizontalAccuracy: 5,
        verticalAccuracy: 3,
        course: 0,
        courseAccuracy: 5,
        speed: 10,
        speedAccuracy: 1
      )
      drive.positions = (drive.positions ?? []) + [position]
    }

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    let trkptCount = content.components(separatedBy: "trkpt").count - 1
    #expect(trkptCount == 10) // 5 open + 5 close tags
  }

  @Test
  func gpxURLExtensionIsGpx() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    #expect(outputURL.pathExtension == "gpx")
  }

  @Test
  func subsequentExportsOverwritePreviousFile() async throws {
    let drive = driveWithOnePosition()
    let service = ExportDriveGPX()

    let firstURL = try await service.export(drive: drive)
    let secondURL = try await service.export(drive: drive)
    defer {
      try? FileManager.default.removeItem(at: firstURL)
    }

    #expect(firstURL == secondURL)
    #expect(FileManager.default.fileExists(atPath: secondURL.path))
  }

  // MARK: - Namespaces & extensions

  @Test
  func gpxFileDeclaresCustomNamespaces() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("xmlns:drv=\"https://www.targatrips.com/gpx/v1\""))
    #expect(content.contains("xmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\""))
  }

  @Test
  func gpxFileWritesPerPointSpeedInGpxtpxNamespace() async throws {
    let drive = driveWithOnePosition()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<gpxtpx:TrackPointExtension>"))
    #expect(content.contains("<gpxtpx:speed>"))
    #expect(!content.contains("<extensions><speed>"))
  }

  // MARK: - Statistics block

  @Test
  func gpxFileContainsStatsBlock() async throws {
    let drive = driveWithMultiplePositions()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<drv:stats>"))
    #expect(content.contains("</drv:stats>"))
  }

  @Test
  func gpxFileContainsAllStatElements() async throws {
    let drive = driveWithMultiplePositions()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    let expectedElements = [
      "drv:distanceMetres",
      "drv:durationSeconds",
      "drv:averageSpeedKmh",
      "drv:meanSpeedKmh",
      "drv:speedStandardDeviationKmh",
      "drv:speedVarianceKmh2",
      "drv:percentTimeAbove80Kmh",
      "drv:sustainedHighSpeedSegmentCount",
      "drv:stopCount",
      "drv:percentTimeStopped",
      "drv:sinuosity",
      "drv:bearingChangeRateDegreesPerKilometre",
      "drv:elevationGainMetres",
      "drv:elevationLossMetres"
    ]
    for element in expectedElements {
      #expect(content.contains("<\(element)>"), "Missing stat element <\(element)>")
    }
  }

  @Test
  func gpxFileContainsCorrectDurationSeconds() async throws {
    let drive = driveWithMultiplePositions()
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 40)

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<drv:durationSeconds>40</drv:durationSeconds>"))
  }

  @Test
  func gpxStatsUseLocaleIndependentDecimalSeparator() async throws {
    let drive = driveWithMultiplePositions()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<drv:sinuosity>"))
    #expect(!content.contains(","), "Numeric values must not use comma decimal/grouping separators")
  }

  // MARK: - Weather block

  @Test
  func gpxFileContainsWeatherBlock() async throws {
    let drive = driveWithMultiplePositions()
    attachWeather(
      to: drive,
      departureDescription: "Partly Cloudy",
      departureTemperatureCelsius: 14.5,
      arrivalDescription: "Clear",
      arrivalTemperatureCelsius: 16.2
    )

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<drv:weather>"))
    #expect(content.contains("</drv:weather>"))
    #expect(content.contains("<drv:departure>"))
    #expect(content.contains("<drv:arrival>"))
    #expect(content.contains("<drv:description>Partly Cloudy</drv:description>"))
    #expect(content.contains("<drv:description>Clear</drv:description>"))
    #expect(content.contains("<drv:temperatureCelsius>14.5</drv:temperatureCelsius>"))
    #expect(content.contains("<drv:temperatureCelsius>16.2</drv:temperatureCelsius>"))
  }

  @Test
  func gpxFileOmitsWeatherBlockWhenNoWeatherData() async throws {
    let drive = driveWithMultiplePositions()

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(!content.contains("<drv:weather>"))
  }

  @Test
  func gpxWeatherBlockEscapesDescription() async throws {
    let drive = driveWithMultiplePositions()
    attachWeather(
      to: drive,
      departureDescription: "Rain & <Wind>",
      departureTemperatureCelsius: 10,
      arrivalDescription: "Sun",
      arrivalTemperatureCelsius: 12
    )

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<drv:description>Rain &amp; &lt;Wind&gt;</drv:description>"))

    let parser = XMLParser(data: Data(content.utf8))
    #expect(parser.parse(), "Escaped output must be well-formed XML")
  }

  @Test
  func gpxWeatherTemperatureUsesLocaleIndependentDecimalSeparator() async throws {
    let drive = driveWithMultiplePositions()
    attachWeather(
      to: drive,
      departureDescription: "Cloudy",
      departureTemperatureCelsius: 1234.5,
      arrivalDescription: "Cloudy",
      arrivalTemperatureCelsius: 1234.5
    )

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(content.contains("<drv:temperatureCelsius>1234.5</drv:temperatureCelsius>"))
  }

  // MARK: - XML escaping

  @Test
  func gpxFileEscapesSpecialCharactersInName() async throws {
    let drive = Drive(name: "Cork & Dublin <fast>")
    let position = Position(
      latitude: 51.5,
      longitude: -0.1,
      altitude: 10,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 0,
      courseAccuracy: 5,
      speed: 10,
      speedAccuracy: 1
    )
    drive.positions = (drive.positions ?? []) + [position]

    let outputURL = try await ExportDriveGPX().export(drive: drive)
    defer { try? FileManager.default.removeItem(at: outputURL) }

    let content = try String(contentsOf: outputURL, encoding: .utf8)
    #expect(!content.contains("Cork & Dublin <fast>"))
    #expect(content.contains("Cork &amp; Dublin &lt;fast&gt;"))

    let parser = XMLParser(data: Data(content.utf8))
    #expect(parser.parse(), "Escaped output must be well-formed XML")
  }

  // MARK: - Helpers

  private func driveWithMultiplePositions() -> Drive {
    let drive = Drive(name: "Stats Drive")
    let base = Date(timeIntervalSinceReferenceDate: 0)
    for i in 0..<5 {
      let position = Position(
        timestamp: base.addingTimeInterval(Double(i) * 10),
        latitude: 51.5 + Double(i) * 0.001,
        longitude: -0.1 + Double(i) * 0.001,
        altitude: 10 + Double(i),
        horizontalAccuracy: 5,
        verticalAccuracy: 3,
        course: Double(i) * 10,
        courseAccuracy: 5,
        speed: Double(i) * 8,
        speedAccuracy: 1
      )
      drive.positions = (drive.positions ?? []) + [position]
    }
    drive.endedAt = base.addingTimeInterval(40)
    return drive
  }

  private func attachWeather(
    to drive: Drive,
    departureDescription: String,
    departureTemperatureCelsius: Double,
    arrivalDescription: String,
    arrivalTemperatureCelsius: Double
  ) {
    let startWeather = Weather(
      temperatureCelsius: departureTemperatureCelsius,
      conditionDescription: departureDescription,
      symbolName: "cloud",
      type: .start
    )
    let endWeather = Weather(
      temperatureCelsius: arrivalTemperatureCelsius,
      conditionDescription: arrivalDescription,
      symbolName: "sun.max",
      type: .end
    )
    drive.weatherReadings = (drive.weatherReadings ?? []) + [startWeather, endWeather]
  }

  private func driveWithOnePosition() -> Drive {
    let drive = Drive(name: "Test Drive")
    let position = Position(
      latitude: 51.5074,
      longitude: -0.1278,
      altitude: 11,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 270,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )
    drive.positions = (drive.positions ?? []) + [position]
    return drive
  }
}
