//
//  RecordingViewModel.swift
//  Driveline
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

  var elapsedDisplay: String { TimeInterval(elapsedSeconds).elapsedTimeString() }

  var elapsedSpeechValue: String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .spellOut
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropLeading
    return formatter.string(from: TimeInterval(elapsedSeconds)) ?? elapsedDisplay
  }
  var distanceValue: String {
    Measurement(value: distanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
  }
  var distanceUnit: String {
    Measurement(value: distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
  }

  var speedValue: String {
    guard !routeService.isPaused else { return kDashString }
    guard let ms = routeService.currentSpeedMs else { return kDashString }
    return Measurement(value: ms, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString()
  }

  var speedUnit: String {
    Measurement(value: routeService.currentSpeedMs ?? 0, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol()
  }
  var positionCount: Int { routeService.route?.positions.count ?? 0 }

  var formattedPositionCount: String {
    Self.formattedCount(positionCount)
  }

  var startedAt: String {
    guard let date = routeService.route?.startedAt else { return kDashString }
    return date.clockString()
  }

  var pauseResumeIconName: String { routeService.isPaused ? SystemImage.play : SystemImage.pause }
  var pauseResumeLabel: String {
    routeService.isPaused ?
    String(localized: "Resume", comment: "Resume a paused drive") :
    String(localized: "Pause", comment: "Pause an active drive")
  }

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

  func endRoute() {
    routeService.endRoute()
  }
}
