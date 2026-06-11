//
//  ExportDriveFileNamingServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("ExportDriveFileNamingService")
@MainActor
final class ExportDriveFileNamingServiceTests: SwiftDataBaseTestCase {

  // MARK: - File extension

  @Test
  func gpxFileURLHasCorrectExtension() {
    let url = ExportDriveFileNamingService.fileURL(for: makeDrive(), type: .gpx)
    #expect(url.pathExtension == "gpx")
  }

  @Test
  func pngFileURLHasCorrectExtension() {
    let url = ExportDriveFileNamingService.fileURL(for: makeDrive(), type: .png)
    #expect(url.pathExtension == "png")
  }

  // MARK: - Filename format

  @Test
  func filenamePrefixMatchesFormattedStartedAt() {
    let drive = makeDrive()
    let expectedPrefix = ExportDriveFileNamingService.startedAtFormatter.string(from: drive.startedAt)
    let url = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)
    #expect(url.lastPathComponent.hasPrefix(expectedPrefix))
  }

  @Test
  func formatterProducesEnglishMonthAbbreviationRegardlessOfSystemLocale() {
    let drive = makeDrive()
    let germanFormatter = DateFormatter()
    germanFormatter.dateFormat = "dd-MMM-yyyy'-'HHmm"
    germanFormatter.timeZone = .current
    germanFormatter.locale = Locale(identifier: "de_DE")
    #expect(germanFormatter.string(from: drive.startedAt).contains("Mai"))
    let formatted = ExportDriveFileNamingService.startedAtFormatter.string(from: drive.startedAt)
    #expect(formatted.contains("May"))
  }

  @Test
  func filenamesForSameDriveDifferOnlyByExtension() {
    let drive = makeDrive()
    let gpxURL = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)
    let pngURL = ExportDriveFileNamingService.fileURL(for: drive, type: .png)
    #expect(gpxURL.deletingPathExtension().lastPathComponent == pngURL.deletingPathExtension().lastPathComponent)
  }

  // MARK: - Location

  @Test
  func fileURLIsInTemporaryDirectory() {
    let url = ExportDriveFileNamingService.fileURL(for: makeDrive(), type: .gpx)
    #expect(url.path.hasPrefix(FileManager.default.temporaryDirectory.path))
  }

  // MARK: - Display name

  @Test
  func filenameIncludesDisplayNameAfterDate() {
    let drive = makeDrive()
    let datePart = ExportDriveFileNamingService.startedAtFormatter.string(from: drive.startedAt)
    let url = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)
    #expect(url.deletingPathExtension().lastPathComponent == "\(datePart) - Test Drive")
  }

  @Test
  func filenameSanitizesReservedCharactersInDisplayName() {
    let drive = makeDrive(name: "Home / Work: A *Quick* Trip?")
    let url = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)
    let name = url.deletingPathExtension().lastPathComponent
    let reserved = CharacterSet(charactersIn: "/\\:*?\"<>|→")
    #expect(name.unicodeScalars.allSatisfy { !reserved.contains($0) })
    #expect(!name.contains("--"))
  }

  @Test
  func filenameSanitizesArrowSeparatorInDisplayName() {
    let drive = makeDrive(name: nil)
    drive.startPlaceName = "Home"
    drive.endPlaceName = "Work"
    let url = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)
    let name = url.deletingPathExtension().lastPathComponent
    #expect(!name.contains("→"))
    #expect(name.hasSuffix("Home - Work"))
  }

  @Test
  func filenameTruncatesLongDisplayNames() {
    let drive = makeDrive(name: String(repeating: "a", count: 200))
    let url = ExportDriveFileNamingService.fileURL(for: drive, type: .gpx)
    let namePart = url.deletingPathExtension().lastPathComponent
      .components(separatedBy: " - ")
      .last ?? ""
    #expect(namePart.count == 80)
  }

  // MARK: - Helpers

  private func makeDrive(name: String? = "Test Drive") -> Drive {
    let drive = Drive(name: name)
    var components = DateComponents()
    components.year = 2026
    components.month = 5
    components.day = 31
    components.hour = 10
    components.minute = 30
    components.timeZone = .current
    drive.startedAt = Calendar.current.date(from: components) ?? .now
    return drive
  }
}
