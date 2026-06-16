//
//  DriveEditorTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("DriveEditor")
@MainActor
struct DriveEditorTests {

  // MARK: - Name

  @Test
  func applyPreservesUserSetName() {
    let drive = makeDrive(name: nil)
    DriveEditor.apply(name: "My Trip", startPlace: "", endPlace: "", to: drive)
    #expect(drive.name == "My Trip")
  }

  @Test
  func applyTrimsWhitespace() {
    let drive = makeDrive(name: nil)
    DriveEditor.apply(name: "  Trip  ", startPlace: "", endPlace: "", to: drive)
    #expect(drive.name == "Trip")
  }

  @Test
  func applySetsNameToNilWhenEmpty() {
    let drive = makeDrive(name: "Old Name")
    DriveEditor.apply(name: "", startPlace: "", endPlace: "", to: drive)
    #expect(drive.name == nil)
  }

  @Test
  func applySetsNameToNilWhenWhitespaceOnly() {
    let drive = makeDrive(name: "Old Name")
    DriveEditor.apply(name: "   ", startPlace: "", endPlace: "", to: drive)
    #expect(drive.name == nil)
  }

  // MARK: - Place Names

  @Test
  func applyPersistsPlaceNames() {
    let drive = makeDrive(name: nil)
    DriveEditor.apply(name: "", startPlace: "Cork", endPlace: "Dublin", to: drive)
    #expect(drive.startPlaceName == "Cork")
    #expect(drive.endPlaceName == "Dublin")
  }

  @Test
  func applyTrimsStartPlaceName() {
    let drive = makeDrive(name: nil)
    DriveEditor.apply(name: "", startPlace: "  Cork  ", endPlace: "", to: drive)
    #expect(drive.startPlaceName == "Cork")
  }

  @Test
  func applySetsStartPlaceToNilWhenEmpty() {
    let drive = makeDrive(name: nil)
    drive.startPlaceName = "Home"
    DriveEditor.apply(name: "", startPlace: "", endPlace: "", to: drive)
    #expect(drive.startPlaceName == nil)
  }

  @Test
  func applySetsEndPlaceToNilWhenWhitespaceOnly() {
    let drive = makeDrive(name: nil)
    drive.endPlaceName = "Office"
    DriveEditor.apply(name: "", startPlace: "", endPlace: "   ", to: drive)
    #expect(drive.endPlaceName == nil)
  }

  // MARK: - Helpers

  private func makeDrive(name: String?) -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 3600)
    return drive
  }
}
