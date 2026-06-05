//
//  AppIntents.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import AppIntents

// MARK: - Intent Dependency Resolver

enum IntentDependencyResolver {
  static var provider: (() -> RouteService?)?
}

// MARK: - App Intent Shortcuts

struct AutoRouteShortcuts: AppShortcutsProvider {

  @AppShortcutsBuilder
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: StartOrResumeRouteIntent(),
      phrases: [
        "Start recording a route with \(.applicationName)",
        "Start a route in \(.applicationName)",
        "Start my route in \(.applicationName)",
        "Resume route with \(.applicationName)",
        "Resume my route with \(.applicationName)"
      ],
      shortTitle: "Start/Resume Route",
      systemImageName: "record.circle"
    )

    AppShortcut(
      intent: PauseRouteIntent(),
      phrases: [
        "Pause recording a route with \(.applicationName)",
        "Pause a route in \(.applicationName)",
        "Pause my route in \(.applicationName)"
      ],
      shortTitle: "Pause Route",
      systemImageName: "pause.circle"
    )
  }
}

// MARK: - Start Or Resume Route Intent

struct StartOrResumeRouteIntent: AppIntent {

  // MARK: - Properties

  static var title: LocalizedStringResource { "Start or resume route" }
  static let description: IntentDescription = .init("Start or resume recording a route.", categoryName: "Route")

  // MARK: - Actions

  func perform() async throws -> some IntentResult {
    await Log.lifecycle.info("Running perform on StartOrResumeRoute intent")

    let routeService = try await resolveRouteService()
    let isPaused = await routeService.isPaused
    let isRecording = await routeService.isRecording

    if isPaused {
      await routeService.resumeRoute()
    } else if !isRecording {
      try await routeService.startRoute(trigger: .automatic)
    }
    return .result()
  }
}

// MARK: - Pause Route Intent

struct PauseRouteIntent: AppIntent {

  // MARK: - Properties

  static var title: LocalizedStringResource { "Pause route" }
  static let description: IntentDescription = .init("Pause recording a route.", categoryName: "Route")

  // MARK: - Actions

  func perform() async throws -> some IntentResult {
    await Log.lifecycle.info("Running perform on PauseRouteIntent intent")

    let routeService = try await resolveRouteService()
    let isRecording = await routeService.isRecording
    let isPaused = await routeService.isPaused

    if isRecording, !isPaused {
      await routeService.pauseRoute()
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
      return "AutoRoute isn't ready to start recording."
    }
  }
}

// MARK: - Private helpers

private func resolveRouteService() async throws -> RouteService {
  guard let routeService = await MainActor.run(body: { IntentDependencyResolver.provider?() }) else {
    throw AppIntentDependencyError.notReady
  }
  return routeService
}
