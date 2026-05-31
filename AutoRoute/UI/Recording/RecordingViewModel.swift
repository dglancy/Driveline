//
//  RecordingViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class RecordingViewModel {

  // MARK: - Properties

  @ObservationIgnored private let routeService: RouteService

  // MARK: - Computed Properties

  var isPaused: Bool { routeService.isPaused }
  var accentColour: Color { routeService.isPaused ? .orange : .red }
  var elapsedSeconds: Int { Int(routeService.route?.activeDurationSeconds ?? 0) }
  var distanceMetres: Double { routeService.route?.distanceMetres ?? 0.0 }

  var speedValue: String {
    guard !routeService.isPaused else { return kDashString }
    return routeService.currentSpeedMs?.localizedSpeedValueString() ?? kDashString
  }

  var speedUnit: String { (routeService.currentSpeedMs ?? 0).localizedSpeedUnitSymbol() }
  var positionCount: Int { routeService.route?.positions.count ?? 0 }

  var formattedPositionCount: String {
    Self.formattedCount(positionCount)
  }

  var startedAt: String {
    guard let date = routeService.route?.startedAt else { return kDashString }
    return date.formatted(.dateTime.hour().minute())
  }

  var triggerIconName: String {
    routeService.route?.trigger == .automatic ? "autostartstop" : "hand.tap"
  }

  var triggerDisplayName: String { routeService.route?.trigger.displayName ?? kBlankString }
  var pauseResumeIconName: String { routeService.isPaused ? "play.fill" : "pause.fill" }
  var pauseResumeLabel: String { routeService.isPaused ? "Resume" : "Pause" }

  // MARK: - Formatting

  private static let positionCountFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
  }()

  static func formattedCount(_ count: Int) -> String {
    if count < 100_000 {
      return positionCountFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
    return count.formatted(.number.notation(.compactName))
  }

  // MARK: - Lifecycle

  init(routeService: RouteService) {
    self.routeService = routeService
  }

  // MARK: - Actions

  func pauseOrResume() {
    if routeService.isPaused {
      routeService.resumeRoute()
    } else {
      routeService.pauseRoute()
    }
  }

  func endRoute() async {
    await routeService.endRoute()
  }
}
