//
//  AppIntentsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
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
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    driveService = DriveRecordingService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService())
    IntentDependencyResolver.provider = { [weak self] in
      self?.driveService
    }
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
    try driveService.startDrive()

    _ = try await StartDriveIntent().perform()

    #expect(driveService.isRecording)
  }

  // MARK: - FinishDriveIntent

  @Test
  func finishDriveIntentFinishesDriveWhenRecording() async throws {
    try driveService.startDrive()

    _ = try await FinishDriveIntent().perform()

    #expect(!driveService.isRecording)
  }

  @Test
  func finishDriveIntentIsNoOpWhenStopped() async throws {
    _ = try await FinishDriveIntent().perform()

    #expect(!driveService.isRecording)
  }
}
