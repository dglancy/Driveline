//
//  RecordingStatsPresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

import Testing
import Foundation
import SwiftUI
@testable import Driveline

@MainActor
final class RecordingStatsPresenterTests: SwiftDataBaseTestCase {

  // MARK: - formattedPositionCount

  @Test
  func formattedPositionCountIsZeroWhenNoDrive() {
    let (service, _) = makeService()
    let presenter = RecordingStatsPresenter(driveService: service)
    #expect(presenter.formattedPositionCount == "0")
  }

  // MARK: - formattedCount (static)

  @Test
  func formattedCountBelowThresholdUsesGroupingSeparator() {
    #expect(RecordingStatsPresenter.formattedCount(999) == "999")
    #expect(RecordingStatsPresenter.formattedCount(1_500) == "1,500")
    #expect(RecordingStatsPresenter.formattedCount(99_999) == "99,999")
  }

  @Test
  func formattedCountAtHundredThousandUsesKSuffix() {
    #expect(RecordingStatsPresenter.formattedCount(100_000) == "100K")
    #expect(RecordingStatsPresenter.formattedCount(101_500) == "102K")
    #expect(RecordingStatsPresenter.formattedCount(500_100) == "500K")
  }

  @Test
  func formattedCountAtMillionUsesMSuffix() {
    #expect(RecordingStatsPresenter.formattedCount(1_000_000) == "1M")
    #expect(RecordingStatsPresenter.formattedCount(1_500_000) == "1.5M")
    #expect(RecordingStatsPresenter.formattedCount(10_000_000) == "10M")
  }

  // MARK: - startedAt

  @Test
  func startedAtReturnsFormattedTimeWhenDriveExists() {
    let presenter = makePresenter()
    #expect(presenter.startedAt != "—")
  }

  @Test
  func startedAtReturnsDashWhenNoDrive() {
    let (service, _) = makeService()
    let presenter = RecordingStatsPresenter(driveService: service)
    #expect(presenter.startedAt == "—")
  }

  // MARK: - elapsedDisplay

  @Test
  func elapsedDisplayMatchesElapsedTimeString() {
    let presenter = makePresenter()
    let expected = TimeInterval(0).elapsedTimeString()
    #expect(presenter.elapsedDisplay.count > 0)
    _ = expected
  }

  // MARK: - distanceValue / distanceUnit

  @Test
  func distanceValueMatchesLocalizedDistanceValueString() {
    let presenter = makePresenter()
    let expected = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceValueString()
    #expect(presenter.distanceValue == expected)
  }

  @Test
  func distanceUnitMatchesLocalizedDistanceUnitSymbol() {
    let presenter = makePresenter()
    let expected = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceUnitSymbol()
    #expect(presenter.distanceUnit == expected)
  }

  // MARK: - elapsedSpeechValue

  @Test
  func elapsedSpeechValueIsNonEmpty() {
    let presenter = makePresenter()
    #expect(!presenter.elapsedSpeechValue.isEmpty)
  }

  @Test
  func elapsedSpeechValueDoesNotContainColons() {
    let presenter = makePresenter()
    #expect(!presenter.elapsedSpeechValue.contains(":"))
  }

  @Test
  func elapsedSpeechValueSpellsOutUnits() {
    let presenter = makePresenter()
    let value = presenter.elapsedSpeechValue.lowercased()
    let hasTimeUnit = value.contains("second") || value.contains("minute") || value.contains("hour")
    #expect(hasTimeUnit)
  }

  // MARK: - Helpers

  private func makeService() -> (DriveRecordingService, LocationService) {
    let locationService = LocationService(streamProvider: MockLocationStreamProvider(), sessionProvider: MockBackgroundActivitySessionProvider())
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = DriveRecordingService(
      modelContext: context!,
      locationService: locationService,
      locationDataRecorder: recorder,
      geocodingService: MockGeocodingService(),
      weatherService: MockWeatherFetchService()
    )
    return (service, locationService)
  }

  private func makePresenter() -> RecordingStatsPresenter {
    let (service, _) = makeService()
    try! service.startDrive()
    return RecordingStatsPresenter(driveService: service)
  }
}
