//
//  AppIntentsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import AppIntents
import Foundation
import SwiftData
import Testing

@Suite(.serialized)
@MainActor
final class AppIntentsTests: SwiftDataBaseTestCase {

  // MARK: - Properties

  private var driveService: DriveRecordingService!

  // MARK: - Lifecycle

  override init() async throws {
    try await super.init()
    let locationService = LocationService(streamProvider: MockLocationStreamProvider(), sessionProvider: MockBackgroundActivitySessionProvider())
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let categoryPredictionSweepService = CategoryPredictionSweepService(modelContainer: container!)
    await categoryPredictionSweepService.configure(classifierService: MockDriveClassifierService())
    driveService = DriveRecordingService(
      modelContext: context!,
      locationService: locationService,
      locationDataRecorder: recorder,
      categoryPredictionSweepService: categoryPredictionSweepService
    )
    IntentDependencyResolver.provider = { [weak self] in
      self?.driveService
    }
    IntentDependencyResolver.modelContextProvider = { [weak self] in
      self?.context
    }
  }

  // MARK: - DrivelineShortcuts

  @Test
  func appShortcutsProvidesStartFinishAndExportShortcuts() {
    let shortcuts = DrivelineShortcuts.appShortcuts
    #expect(shortcuts.count == 3)
  }

  // MARK: - IntentDependencyResolver

  @Test
  func resolveServicesThrowsWhenProviderIsNil() async throws {
    IntentDependencyResolver.provider = nil

    await #expect(throws: AppIntentDependencyError.self) {
      try await StartDriveIntent().perform()
    }
  }

  @Test
  func resolveServicesThrowsWhenProviderReturnsNil() async throws {
    IntentDependencyResolver.provider = { nil }

    await #expect(throws: AppIntentDependencyError.self) {
      try await StartDriveIntent().perform()
    }
  }

  // MARK: - StartDriveIntent

  @Test
  func startDriveIntentStartsDriveWhenStopped() async throws {
    _ = try await StartDriveIntent().perform()

    #expect(driveService.isRecording)
  }

  @Test
  func startDriveIntentIsNoOpWhenAlreadyRecording() async throws {
    driveService.startDrive()

    _ = try await StartDriveIntent().perform()

    #expect(driveService.isRecording)
  }

  // MARK: - FinishDriveIntent

  @Test
  func finishDriveIntentFinishesDriveWhenRecording() async throws {
    driveService.startDrive()

    _ = try await FinishDriveIntent().perform()

    #expect(!driveService.isRecording)
  }

  @Test
  func finishDriveIntentIsNoOpWhenStopped() async throws {
    _ = try await FinishDriveIntent().perform()

    #expect(!driveService.isRecording)
  }

  // MARK: - ExportLatestDriveGPXIntent

  @Test
  func exportLatestDriveIntentThrowsWhenThereIsNoFinishedDrive() async throws {
    await #expect(throws: LatestDriveGPXExportError.noFinishedDrive) {
      try await ExportLatestDriveGPXIntent().perform()
    }
  }

  @Test
  func exportLatestDriveIntentThrowsWhenLatestDriveHasNoCoordinates() async throws {
    insertFinishedDrive(name: "Empty", endedAt: .now)

    await #expect(throws: LatestDriveGPXExportError.noCoordinates) {
      try await ExportLatestDriveGPXIntent().perform()
    }
  }

  @Test
  func exportLatestDriveIntentExportsMostRecentlyFinishedDrive() async throws {
    insertFinishedDrive(name: "Older", endedAt: .now.addingTimeInterval(-60), withPosition: true)
    insertFinishedDrive(name: "Newest", endedAt: .now, withPosition: true)

    let result = try await ExportLatestDriveGPXIntent().perform()
    let file = try #require(result.value)
    let fileURL = try #require(file.fileURL)
    let content = try String(contentsOf: fileURL, encoding: .utf8)

    #expect(file.filename.hasSuffix(".gpx"))
    #expect(content.contains("<name>Newest</name>"))
  }

  // MARK: - Helpers

  @discardableResult
  private func insertFinishedDrive(
    name: String,
    endedAt: Date,
    withPosition: Bool = false
  ) -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = endedAt.addingTimeInterval(-30)
    drive.endedAt = endedAt
    drive.status = .finished
    if withPosition {
      drive.positions = [Position(
        timestamp: drive.startedAt,
        latitude: 53.3498,
        longitude: -6.2603,
        altitude: 10,
        horizontalAccuracy: 5,
        verticalAccuracy: 5,
        course: 0,
        courseAccuracy: 1,
        speed: 10,
        speedAccuracy: 1
      )]
    }
    context!.insert(drive)
    return drive
  }
}
