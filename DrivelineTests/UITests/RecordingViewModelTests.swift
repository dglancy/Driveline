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

  // MARK: - isPaused

  @Test
  func isPausedIsFalseWhenRouteIsRunning() {
    let vm = makeViewModel()
    #expect(vm.isPaused == false)
  }

  @Test
  func isPausedIsTrueWhenRoutePaused() {
    let vm = makeViewModel(paused: true)
    #expect(vm.isPaused == true)
  }

  // MARK: - accentColour

  @Test
  func accentColourIsRedWhenRunning() {
    let vm = makeViewModel()
    #expect(vm.accentColour == Color.red)
  }

  @Test
  func accentColourIsOrangeWhenPaused() {
    let vm = makeViewModel(paused: true)
    #expect(vm.accentColour == Color.orange)
  }

  // MARK: - speedValue

  @Test
  func speedValueIsEmDashWhenPaused() {
    let vm = makeViewModel(paused: true)
    #expect(vm.speedValue == "—")
  }

  @Test
  func speedValueIsEmDashWhenRunningWithNoSpeed() {
    let vm = makeViewModel()
    #expect(vm.speedValue == "—")
  }

  // MARK: - pauseResumeIconName

  @Test
  func pauseResumeIconNameIsPauseFillWhenRunning() {
    let vm = makeViewModel()
    #expect(vm.pauseResumeIconName == SystemImage.pause)
  }

  @Test
  func pauseResumeIconNameIsPlayFillWhenPaused() {
    let vm = makeViewModel(paused: true)
    #expect(vm.pauseResumeIconName == SystemImage.play)
  }

  // MARK: - pauseResumeLabel

  @Test
  func pauseResumeLabelIsPauseWhenRunning() {
    let vm = makeViewModel()
    #expect(vm.pauseResumeLabel == "Pause")
  }

  @Test
  func pauseResumeLabelIsResumeWhenPaused() {
    let vm = makeViewModel(paused: true)
    #expect(vm.pauseResumeLabel == "Resume")
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

  // MARK: - pauseOrResume

  @Test
  func pauseOrResumeFromRunningPausesService() {
    let (service, vm) = makeServiceAndViewModel()
    vm.pauseOrResume()
    #expect(service.isPaused == true)
  }

  @Test
  func pauseOrResumeFromPausedResumesService() {
    let (service, vm) = makeServiceAndViewModel()
    service.pauseRoute()
    vm.pauseOrResume()
    #expect(service.isPaused == false)
  }

  // MARK: - endRoute

  @Test
  func endRouteStopsRecording() {
    let (service, vm) = makeServiceAndViewModel()
    vm.endRoute()
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

  private func makeViewModel(paused: Bool = false) -> RecordingViewModel {
    let (service, _) = makeService()
    try! service.startRoute()
    if paused { service.pauseRoute() }
    return RecordingViewModel(routeService: service)
  }

  private func makeServiceAndViewModel() -> (RouteService, RecordingViewModel) {
    let (service, _) = makeService()
    try! service.startRoute()
    return (service, RecordingViewModel(routeService: service))
  }
}
