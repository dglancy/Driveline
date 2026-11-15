//
//  AppIntents.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import AppIntents
import SwiftData
import UniformTypeIdentifiers

// MARK: - Intent Dependency Resolver

enum IntentDependencyResolver {

  // MARK: - Properties

  static var provider: (() -> DriveRecordingService?)?
  static var modelContextProvider: (() -> ModelContext?)?
}

// MARK: - App Intent Shortcuts

struct DrivelineShortcuts: AppShortcutsProvider {

  // MARK: - Computed Properties

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

    AppShortcut(
      intent: ExportLatestDriveGPXIntent(),
      phrases: [
        "Export my latest drive with \(.applicationName)",
        "Export my latest drive as GPX with \(.applicationName)",
        "Get my latest drive GPX file with \(.applicationName)"
      ],
      shortTitle: "Get Latest GPX File",
      systemImageName: "square.and.arrow.up"
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
    Log.lifecycle.info("Running perform on StartDriveIntent intent")

    let driveService = try await resolveDriveRecordingService()
    if await !driveService.isRecording {
      await driveService.startDrive(trigger: .automatic)
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
    Log.lifecycle.info("Running perform on FinishDriveIntent intent")

    let driveService = try await resolveDriveRecordingService()
    if await driveService.isRecording {
      await driveService.finishDrive()
    }
    return .result()
  }
}

// MARK: - Export Latest Drive GPX Intent

struct ExportLatestDriveGPXIntent: AppIntent {

  // MARK: - Properties

  static var title: LocalizedStringResource { "Get latest drive GPX file" }
  static let description: IntentDescription = .init(
    "Creates a GPX file for the most recently finished drive. Add a Save File, Share, or upload action afterward to use the file.",
    categoryName: "Drive"
  )
  static var supportedModes: IntentModes { .background }
  static var allowedExecutionTargets: IntentExecutionTargets { .main }

  // MARK: - Actions

  @MainActor
  func perform() async throws -> some ReturnsValue<IntentFile> {
    Log.lifecycle.info("Running perform on ExportLatestDriveGPXIntent intent")

    let modelContext = try resolveModelContext()
    do {
      let fileURL = try await LatestDriveGPXExporter(modelContext: modelContext).export()
      var file = IntentFile(fileURL: fileURL, filename: fileURL.lastPathComponent, type: .xml)
      file.removedOnCompletion = true
      return .result(value: file)
    } catch let error as LatestDriveGPXExportError {
      throw error
    } catch ExportError.emptyDrive {
      throw LatestDriveGPXExportError.noCoordinates
    } catch {
      Log.data.error("Failed to export latest drive as GPX: \(error.localizedDescription)")
      throw LatestDriveGPXExportError.exportFailed
    }
  }
}

// MARK: - Latest Drive GPX Exporter

@MainActor
struct LatestDriveGPXExporter {

  // MARK: - Properties

  let modelContext: ModelContext

  // MARK: - Actions

  func export() async throws -> URL {
    let descriptor = FetchDescriptor<Drive>(
      sortBy: [SortDescriptor(\Drive.endedAt, order: .reverse)]
    )
    let drives = try modelContext.fetch(descriptor)
    guard let drive = drives.first(where: { $0.status == .finished }) else {
      throw LatestDriveGPXExportError.noFinishedDrive
    }
    return try await ExportDriveGPX().export(drive: drive)
  }
}

// MARK: - Error enums

enum AppIntentDependencyError: Error, CustomLocalizedStringResourceConvertible {
  case notReady

  // MARK: - Computed Properties

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .notReady:
      return "Driveline isn't ready to start recording."
    }
  }
}

enum LatestDriveGPXExportError: Error, Equatable, CustomLocalizedStringResourceConvertible {
  case noFinishedDrive
  case noCoordinates
  case exportFailed

  // MARK: - Computed Properties

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .noFinishedDrive:
      return "There isn't a finished drive to export."
    case .noCoordinates:
      return "The latest drive doesn't contain any recorded coordinates."
    case .exportFailed:
      return "Driveline couldn't prepare the GPX file. Please try again."
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

@MainActor
private func resolveModelContext() throws -> ModelContext {
  guard let modelContext = IntentDependencyResolver.modelContextProvider?() else {
    throw AppIntentDependencyError.notReady
  }
  return modelContext
}
