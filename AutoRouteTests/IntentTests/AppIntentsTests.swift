//
//  AppIntentsTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
import Foundation
import SwiftData
import Testing

@Suite(.serialized)
@MainActor
final class AppIntentsTests: SwiftDataBaseTestCase {

  // MARK: - Properties

  private var routeService: RouteService!

  // MARK: - Lifecycle

  override init() async throws {
    try await super.init()
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    routeService = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)
    IntentDependencyResolver.provider = { [weak self] in
      self?.routeService
    }
  }

  // MARK: - IntentDependencyResolver

  @Test
  func resolveServicesThrowsWhenProviderIsNil() async throws {
    IntentDependencyResolver.provider = nil

    await #expect(throws: AppIntentDependencyError.self) {
      try await StartOrResumeRouteIntent().perform()
    }
  }

  @Test
  func resolveServicesThrowsWhenProviderReturnsNil() async throws {
    IntentDependencyResolver.provider = { nil }

    await #expect(throws: AppIntentDependencyError.self) {
      try await StartOrResumeRouteIntent().perform()
    }
  }

  // MARK: - StartOrResumeRouteIntent

  @Test
  func startOrResumeIntentStartsRouteWhenStopped() async throws {
    _ = try await StartOrResumeRouteIntent().perform()

    #expect(routeService.isRecording)
    #expect(!routeService.isPaused)
  }

  @Test
  func startOrResumeIntentResumesRouteWhenPaused() async throws {
    try routeService.startRoute()
    routeService.pauseRoute()

    _ = try await StartOrResumeRouteIntent().perform()

    #expect(routeService.isRecording)
    #expect(!routeService.isPaused)
  }

  @Test
  func startOrResumeIntentIsNoOpWhenAlreadyStarted() async throws {
    try routeService.startRoute()

    _ = try await StartOrResumeRouteIntent().perform()

    #expect(routeService.isRecording)
    #expect(!routeService.isPaused)
  }

  // MARK: - PauseRouteIntent

  @Test
  func pauseIntentPausesRouteWhenStarted() async throws {
    try routeService.startRoute()

    _ = try await PauseRouteIntent().perform()

    #expect(routeService.isPaused)
  }

  @Test
  func pauseIntentIsNoOpWhenAlreadyPaused() async throws {
    try routeService.startRoute()
    routeService.pauseRoute()

    _ = try await PauseRouteIntent().perform()

    #expect(routeService.isPaused)
  }

  @Test
  func pauseIntentIsNoOpWhenStopped() async throws {
    _ = try await PauseRouteIntent().perform()

    #expect(!routeService.isRecording)
    #expect(!routeService.isPaused)
  }
}
