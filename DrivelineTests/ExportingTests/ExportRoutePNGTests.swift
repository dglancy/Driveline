//
//  ExportDrivePNGTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("ExportDrivePNG")
@MainActor
final class ExportDrivePNGTests: SwiftDataBaseTestCase {

  // MARK: - Error descriptions

  @Test
  func snapshotFailureHasUserFacingDescription() {
    let error = ExportError.pngSnapshotFailure
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription?.isEmpty == false)
  }

  @Test
  func dataPreparationFailureHasUserFacingDescription() {
    let error = ExportError.pngDataPreparationFailure
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription?.isEmpty == false)
  }

  @Test
  func fileWriteFailureHasUserFacingDescription() {
    let error = ExportError.pngFileWriteFailure
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription?.isEmpty == false)
  }

  // MARK: - MapSize dimensions

  @Test
  func lowSizeIsCorrect() {
    #expect(MapSize.low.size == CGSize(width: 800, height: 600))
  }

  @Test
  func mediumSizeIsCorrect() {
    #expect(MapSize.medium.size == CGSize(width: 1024, height: 768))
  }

  @Test
  func high1SizeIsCorrect() {
    #expect(MapSize.high1.size == CGSize(width: 1600, height: 1200))
  }

  @Test
  func high2SizeIsCorrect() {
    #expect(MapSize.high2.size == CGSize(width: 1920, height: 1080))
  }

  @Test
  func highestSizeIsCorrect() {
    #expect(MapSize.highest.size == CGSize(width: 2400, height: 1800))
  }

  // MARK: - MapSize initialiser

  @Test
  func mapSizeInitialisesFromValidLowercaseString() {
    #expect(MapSize(from: "low") == .low)
    #expect(MapSize(from: "medium") == .medium)
    #expect(MapSize(from: "high1") == .high1)
    #expect(MapSize(from: "high2") == .high2)
    #expect(MapSize(from: "highest") == .highest)
  }

  @Test
  func mapSizeInitialisesFromMixedCaseString() {
    #expect(MapSize(from: "LOW") == .low)
    #expect(MapSize(from: "High2") == .high2)
    #expect(MapSize(from: "HIGHEST") == .highest)
  }

  @Test
  func mapSizeInitialisesFromStringWithSurroundingWhitespace() {
    #expect(MapSize(from: "  low  ") == .low)
    #expect(MapSize(from: "\thigh2\n") == .high2)
  }

  @Test
  func mapSizeReturnsNilForInvalidString() {
    #expect(MapSize(from: "ultra") == nil)
    #expect(MapSize(from: "") == nil)
  }

  // MARK: - DriveWidth values

  @Test
  func driveWidthValuesAreCorrect() {
    #expect(DriveWidth.thin.width == 3.0)
    #expect(DriveWidth.medium.width == 6.0)
    #expect(DriveWidth.thick.width == 9.0)
  }

  // MARK: - DriveWidth initialiser

  @Test
  func driveWidthInitialisesFromValidLowercaseString() {
    #expect(DriveWidth(from: "thin") == .thin)
    #expect(DriveWidth(from: "medium") == .medium)
    #expect(DriveWidth(from: "thick") == .thick)
  }

  @Test
  func driveWidthInitialisesFromMixedCaseString() {
    #expect(DriveWidth(from: "THIN") == .thin)
    #expect(DriveWidth(from: "Medium") == .medium)
    #expect(DriveWidth(from: "THICK") == .thick)
  }

  @Test
  func driveWidthInitialisesFromStringWithSurroundingWhitespace() {
    #expect(DriveWidth(from: "  thin  ") == .thin)
  }

  @Test
  func driveWidthReturnsNilForInvalidString() {
    #expect(DriveWidth(from: "ultrawide") == nil)
    #expect(DriveWidth(from: "") == nil)
  }

  // MARK: - Empty drive

  @Test
  func throwsEmptyDriveErrorWhenDriveHasNoPositions() async {
    let drive = Drive(name: "Empty Drive")

    await #expect(throws: ExportError.emptyDrive) {
      _ = try await ExportDrivePNG().export(drive: drive)
    }
  }
}
