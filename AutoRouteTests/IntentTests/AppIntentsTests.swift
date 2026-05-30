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
  private var locationService: LocationService!

  // MARK: - Lifecycle

  override init() async throws {
    try await super.init()
    locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    routeService = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder)
    IntentDependencyResolver.provider = { [weak self] in
      guard let self else { return nil }
      return (routeService: routeService, locationService: locationService)
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

    #expect(locationService.status == .started)
  }

  @Test
  func startOrResumeIntentResumesRouteWhenPaused() async throws {
    routeService.startRoute()
    routeService.pauseRoute()

    _ = try await StartOrResumeRouteIntent().perform()

    #expect(locationService.status == .started)
  }

  @Test
  func startOrResumeIntentIsNoOpWhenAlreadyStarted() async throws {
    routeService.startRoute()

    _ = try await StartOrResumeRouteIntent().perform()

    #expect(locationService.status == .started)
  }

  // MARK: - PauseRouteIntent

  @Test
  func pauseIntentPausesRouteWhenStarted() async throws {
    routeService.startRoute()

    _ = try await PauseRouteIntent().perform()

    #expect(locationService.status == .paused)
  }

  @Test
  func pauseIntentIsNoOpWhenAlreadyPaused() async throws {
    routeService.startRoute()
    routeService.pauseRoute()

    _ = try await PauseRouteIntent().perform()

    #expect(locationService.status == .paused)
  }

  @Test
  func pauseIntentIsNoOpWhenStopped() async throws {
    _ = try await PauseRouteIntent().perform()

    #expect(locationService.status == .stopped)
  }
}
