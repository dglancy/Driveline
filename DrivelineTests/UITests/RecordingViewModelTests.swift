//
//  RecordingViewModelTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
import SwiftUI
@testable import Driveline

@MainActor
final class RecordingViewModelTests: SwiftDataBaseTestCase {

  // MARK: - speedValue

  @Test
  func speedValueIsEmDashWhenRunningWithNoSpeed() {
    let vm = makeViewModel()
    #expect(vm.speedValue == "—")
  }

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
  func startedAtReturnsFormattedTimeWhenRouteExists() {
    let vm = makeViewModel()
    #expect(vm.startedAt != "—")
  }

  // MARK: - finishRoute

  @Test
  func finishRouteStopsRecording() {
    let (service, vm) = makeServiceAndViewModel()
    vm.finishRoute()
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

  private func makeService() -> (RouteService, LocationService) {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = RouteService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService())
    return (service, locationService)
  }

  private func makeViewModel() -> RecordingViewModel {
    let (service, _) = makeService()
    try! service.startRoute()
    return RecordingViewModel(routeService: service)
  }

  private func makeServiceAndViewModel() -> (RouteService, RecordingViewModel) {
    let (service, _) = makeService()
    try! service.startRoute()
    return (service, RecordingViewModel(routeService: service))
  }
}
