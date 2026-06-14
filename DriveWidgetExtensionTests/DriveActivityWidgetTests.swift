//
//  DriveActivityWidgetTests.swift
//  DriveWidgetExtensionTests
//
//  Created by Damien Glancy on 14/06/2026.
//

import Foundation
import Testing

@Suite
@MainActor
struct DriveActivityWidgetTests {

  // MARK: - Formatting Helpers

  @Test("formattedDistance returns a non-empty string")
  func testFormattedDistanceNotEmpty() {
    #expect(!formattedDistance(1_000).isEmpty)
  }

  @Test("distanceUnitSymbol returns km or mi")
  func testDistanceUnitSymbol() {
    #expect(["km", "mi"].contains(distanceUnitSymbol()))
  }

  @Test("formattedSpeed returns a non-empty string")
  func testFormattedSpeedNotEmpty() {
    #expect(!formattedSpeed(10).isEmpty)
  }

  @Test("speedUnitSymbol returns km/h or mph")
  func testSpeedUnitSymbol() {
    #expect(["km/h", "mph"].contains(speedUnitSymbol()))
  }

  // MARK: - LiveActivityStatColumn

  @Test("LiveActivityStatColumn stores and renders its values")
  func testLiveActivityStatColumn() {
    let view = LiveActivityStatColumn(value: "12.3", label: "km", sublabel: "Distance")
    #expect(view.value == "12.3")
    #expect(view.label == "km")
    #expect(view.sublabel == "Distance")
    _ = view.body
  }

  // MARK: - LiveActivityTimerColumn

  @Test("LiveActivityTimerColumn stores and renders its start date")
  func testLiveActivityTimerColumn() {
    let startedAt = Date()
    let view = LiveActivityTimerColumn(startedAt: startedAt)
    #expect(view.startedAt == startedAt)
    _ = view.body
  }
}
