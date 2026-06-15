//
//  RecordingViewModelTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
import SwiftUI
@testable import Driveline

@MainActor
final class RecordingViewModelTests: SwiftDataBaseTestCase {

  // MARK: - positionCount

  @Test
  func positionCountIsZeroWithNoPositions() {
    let vm = makeViewModel()
    #expect(vm.positionCount == 0)
  }

  // MARK: - formattedPositionCount

  @Test
  func formattedPositionCountIsZeroWithNoPositions() {
    let vm = makeViewModel()
    #expect(vm.formattedPositionCount == "0")
  }

  @Test
  func formattedCountBelowThresholdUsesGroupingSeparator() {
    #expect(RecordingViewModel.formattedCount(999) == "999")
    #expect(RecordingViewModel.formattedCount(1_500) == "1,500")
    #expect(RecordingViewModel.formattedCount(99_999) == "99,999")
  }

  @Test
  func formattedCountAtHundredThousandUsesKSuffix() {
    #expect(RecordingViewModel.formattedCount(100_000) == "100K")
    #expect(RecordingViewModel.formattedCount(101_500) == "102K")
    #expect(RecordingViewModel.formattedCount(500_100) == "500K")
  }

  @Test
  func formattedCountAtMillionUsesMSuffix() {
    #expect(RecordingViewModel.formattedCount(1_000_000) == "1M")
    #expect(RecordingViewModel.formattedCount(1_500_000) == "1.5M")
    #expect(RecordingViewModel.formattedCount(10_000_000) == "10M")
  }

  // MARK: - startedAt

  @Test
  func startedAtReturnsFormattedTimeWhenDriveExists() {
    let vm = makeViewModel()
    #expect(vm.startedAt != "—")
  }

  @Test
  func startedAtReturnsDashWhenNoDriveExists() {
    let (service, _) = makeService()
    let vm = RecordingViewModel(driveService: service)
    #expect(vm.startedAt == "—")
  }

  // MARK: - elapsedSeconds / distanceMetres

  @Test
  func elapsedSecondsIsZeroForFreshDrive() {
    let vm = makeViewModel()
    #expect(vm.elapsedSeconds <= 1)
  }

  @Test
  func distanceMetresIsZeroForFreshDrive() {
    let vm = makeViewModel()
    #expect(vm.distanceMetres == 0)
  }

  @Test
  func elapsedSecondsIsZeroWhenNoDriveExists() {
    let (service, _) = makeService()
    let vm = RecordingViewModel(driveService: service)
    #expect(vm.elapsedSeconds == 0)
  }

  @Test
  func distanceMetresIsZeroWhenNoDriveExists() {
    let (service, _) = makeService()
    let vm = RecordingViewModel(driveService: service)
    #expect(vm.distanceMetres == 0)
  }

  // MARK: - elapsedDisplay

  @Test
  func elapsedDisplayMatchesElapsedTimeString() {
    let vm = makeViewModel()
    #expect(vm.elapsedDisplay == TimeInterval(vm.elapsedSeconds).elapsedTimeString())
  }

  // MARK: - distanceValue / distanceUnit

  @Test
  func distanceValueMatchesLocalizedDistanceValueString() {
    let vm = makeViewModel()
    let expected = Measurement(value: vm.distanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
    #expect(vm.distanceValue == expected)
  }

  @Test
  func distanceUnitMatchesLocalizedDistanceUnitSymbol() {
    let vm = makeViewModel()
    let expected = Measurement(value: vm.distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
    #expect(vm.distanceUnit == expected)
  }

  // MARK: - finishDrive

  @Test
  func finishDriveStopsRecording() {
    let (service, vm) = makeServiceAndViewModel()
    vm.finishDrive()
    #expect(service.isRecording == false)
  }

  // MARK: - elapsedSpeechValue

  @Test
  func elapsedSpeechValueIsNonEmptyAtZeroSeconds() {
    let vm = makeViewModel()
    #expect(!vm.elapsedSpeechValue.isEmpty)
  }

  @Test
  func elapsedSpeechValueDoesNotContainColons() {
    let vm = makeViewModel()
    #expect(!vm.elapsedSpeechValue.contains(":"))
  }

  @Test
  func elapsedSpeechValueSpellsOutUnits() {
    let vm = makeViewModel()
    let value = vm.elapsedSpeechValue.lowercased()
    let hasTimeUnit = value.contains("second") || value.contains("minute") || value.contains("hour")
    #expect(hasTimeUnit)
  }

  // MARK: - Helpers

  private func makeService() -> (DriveRecordingService, LocationService) {
    let locationService = LocationService()
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

  private func makeViewModel() -> RecordingViewModel {
    let (service, _) = makeService()
    try! service.startDrive()
    return RecordingViewModel(driveService: service)
  }

  private func makeServiceAndViewModel() -> (DriveRecordingService, RecordingViewModel) {
    let (service, _) = makeService()
    try! service.startDrive()
    return (service, RecordingViewModel(driveService: service))
  }
}
