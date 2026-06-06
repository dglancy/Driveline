//
//  DriveDetailViewModelTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("DriveDetailViewModel")
@MainActor
struct DriveDetailViewModelTests {

  // MARK: - Initial State

  @Test
  func showSharingDialogIsFalseByDefault() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.showSharingDialog == false)
  }

  @Test
  func showingFullScreenMapIsFalseByDefault() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.showingFullScreenMap == false)
  }

  @Test
  func exportedFileIsNilByDefault() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.exportedFile == nil)
  }

  @Test
  func exportErrorIsNilByDefault() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.exportError == nil)
  }

  // MARK: - Computed Properties

  @Test
  func nameReturnsDriveName() {
    let vm = DriveDetailViewModel(drive: makeDrive(name: "Dublin to Cork"))
    #expect(vm.name == "Dublin to Cork")
  }

  @Test
  func startPlaceReturnsDriveStartPlaceName() {
    let drive = makeDrive()
    drive.startPlaceName = "Home"
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.startPlace == "Home")
  }

  @Test
  func endPlaceReturnsDriveEndPlaceName() {
    let drive = makeDrive()
    drive.endPlaceName = "Office"
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.endPlace == "Office")
  }

  @Test
  func startPlaceIsNilWhenNotSet() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.startPlace == nil)
  }

  @Test
  func endPlaceIsNilWhenNotSet() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.endPlace == nil)
  }

  @Test
  func arrivalTimeIsNilWhenDriveHasNoEndDate() {
    let drive = makeDrive()
    drive.endedAt = nil
    let vm = DriveDetailViewModel(drive: drive)
    #expect(vm.arrivalTime == nil)
  }

  @Test
  func arrivalTimeIsNonNilWhenDriveHasEndDate() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.arrivalTime != nil)
  }

  @Test
  func trackPointsReflectsZeroPositionCount() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.trackPoints == "0")
  }

  @Test
  func triggerDisplayNameMatchesDriveTrigger() {
    let vm = DriveDetailViewModel(drive: makeDrive())
    #expect(vm.triggerDisplayName == Drive.RecordingTrigger.manual.displayName)
  }

  // MARK: - shareDriveGPX

  @Test
  func shareDriveGPXWithEmptyDriveSetsExportError() async {
    let vm = DriveDetailViewModel(drive: makeDrive())
    vm.shareDriveGPX()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportError != nil)
  }

  @Test
  func shareDriveGPXWithEmptyDriveDoesNotSetExportedFile() async {
    let vm = DriveDetailViewModel(drive: makeDrive())
    vm.shareDriveGPX()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportedFile == nil)
  }

  @Test
  func shareDriveGPXWithPositionsSetsExportedFile() async throws {
    let vm = DriveDetailViewModel(drive: driveWithOnePosition())
    vm.shareDriveGPX()
    for _ in 0..<20 { await Task.yield() }
    let file = try #require(vm.exportedFile)
    defer { try? FileManager.default.removeItem(at: file.url) }
    #expect(vm.exportError == nil)
    #expect(file.url.pathExtension == "gpx")
    #expect(FileManager.default.fileExists(atPath: file.url.path))
  }

  // MARK: - shareDrivePNG

  @Test
  func shareDrivePNGWithEmptyDriveSetsExportError() async {
    let vm = DriveDetailViewModel(drive: makeDrive())
    vm.shareDrivePNG()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportError != nil)
  }

  @Test
  func shareDrivePNGWithEmptyDriveDoesNotSetExportedFile() async {
    let vm = DriveDetailViewModel(drive: makeDrive())
    vm.shareDrivePNG()
    for _ in 0..<10 { await Task.yield() }
    #expect(vm.exportedFile == nil)
  }

  // MARK: - ExportedFile

  @Test
  func exportedFileHasUniqueIDs() {
    let url = URL(fileURLWithPath: "/tmp/test.gpx")
    let a = ExportedFile(url: url)
    let b = ExportedFile(url: url)
    #expect(a.id != b.id)
  }

  @Test
  func exportedFileStoresURL() {
    let url = URL(fileURLWithPath: "/tmp/test.gpx")
    let file = ExportedFile(url: url)
    #expect(file.url == url)
  }

  // MARK: - Helpers

  private func makeDrive(name: String = "Test Drive") -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 3600)
    return drive
  }

  private func driveWithOnePosition() -> Drive {
    let drive = makeDrive()
    drive.positions = (drive.positions ?? []) + [Position(
      latitude: 51.5074,
      longitude: -0.1278,
      altitude: 11,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 270,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )]
    return drive
  }
}
