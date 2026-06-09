//
//  AppIntents.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import AppIntents

// MARK: - Intent Dependency Resolver

enum IntentDependencyResolver {
  static var provider: (() -> DriveRecordingService?)?
}

// MARK: - App Intent Shortcuts

struct DrivelineShortcuts: AppShortcutsProvider {

  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartDriveIntent(),
      phrases: [
        "Start recording a drive with \(.applicationName)",
        "Start a drive in \(.applicationName)",
        "Start my drive in \(.applicationName)"
      ],
      shortTitle: "Start Drive",
      systemImageName: "record.circle"
    )

    AppShortcut(
      intent: FinishDriveIntent(),
      phrases: [
        "Finish recording a drive with \(.applicationName)",
        "Finish a drive in \(.applicationName)",
        "Finish my drive in \(.applicationName)"
      ],
      shortTitle: "Finish Drive",
      systemImageName: "stop.circle"
    )
  }
}

// MARK: - Start Drive Intent

struct StartDriveIntent: AppIntent {

  // MARK: - Properties

  static var title: LocalizedStringResource { "Start drive" }
  static let description: IntentDescription = .init("Start recording a drive.", categoryName: "Drive")

  // MARK: - Actions

  func perform() async throws -> some IntentResult {
    await Log.lifecycle.info("Running perform on StartDriveIntent intent")

    let driveService = try await resolveDriveRecordingService()
    if await !driveService.isRecording {
      try await driveService.startDrive(trigger: .automatic)
    }
    return .result()
  }
}

// MARK: - Finish Drive Intent

struct FinishDriveIntent: LiveActivityIntent {

  // MARK: - Properties

  static var title: LocalizedStringResource { "Finish drive" }
  static let description: IntentDescription = .init("Finish recording a drive.", categoryName: "Drive")

  // MARK: - Actions

  func perform() async throws -> some IntentResult {
    await Log.lifecycle.info("Running perform on FinishDriveIntent intent")

    let driveService = try await resolveDriveRecordingService()
    if await driveService.isRecording {
      await driveService.finishDrive()
    }
    return .result()
  }
}

// MARK: - Error enums

enum AppIntentDependencyError: Error, CustomLocalizedStringResourceConvertible {
  case notReady

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .notReady:
      return "Driveline isn't ready to start recording."
    }
  }
}

// MARK: - Private helpers

private func resolveDriveRecordingService() async throws -> DriveRecordingService {
  guard let driveService = await MainActor.run(body: { IntentDependencyResolver.provider?() }) else {
    throw AppIntentDependencyError.notReady
  }
  return driveService
}
