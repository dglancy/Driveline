//
//  MergeDrivesViewModelTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 08/06/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("MergeDrivesViewModel")
@MainActor
struct MergeDrivesViewModelTests {

  // MARK: - Initialization

  @Test
  func initialOrderMatchesInput() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    #expect(vm.orderedDrives[0].id == first.id)
    #expect(vm.orderedDrives[1].id == second.id)
  }

  @Test
  func defaultMergedNameCombinesBothDriveDisplayNames() {
    let first = makeDrive(name: "Morning Commute", startOffset: 0)
    let second = makeDrive(name: "Evening Drive", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    #expect(vm.mergedName == "Morning Commute + Evening Drive")
  }

  @Test
  func mergedNameIsMutable() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    vm.mergedName = "Custom Name"
    #expect(vm.mergedName == "Custom Name")
  }

  // MARK: - swapOrder

  @Test
  func swapOrderReversesTheDriveOrder() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    vm.swapOrder()
    #expect(vm.orderedDrives[0].id == second.id)
    #expect(vm.orderedDrives[1].id == first.id)
  }

  @Test
  func swapOrderUpdatesMergedName() {
    let first = makeDrive(name: "Alpha", startOffset: 0)
    let second = makeDrive(name: "Beta", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    vm.swapOrder()
    #expect(vm.mergedName == "Beta + Alpha")
  }

  @Test
  func swapOrderTwiceRestoresOriginalOrder() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    vm.swapOrder()
    vm.swapOrder()
    #expect(vm.orderedDrives[0].id == first.id)
    #expect(vm.orderedDrives[1].id == second.id)
  }

  // MARK: - formattedTotalDistance

  @Test
  func formattedTotalDistanceIsFormattedZeroWhenNeitherDriveHasPositions() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    let expected = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceString()
    #expect(vm.formattedTotalDistance == expected)
  }

  // MARK: - formattedTotalDuration

  @Test
  func formattedTotalDurationSumsBothDriveDurations() {
    let first = makeDrive(name: "First", startOffset: 0, endOffset: 3600)
    let second = makeDrive(name: "Second", startOffset: 3600, endOffset: 7200)
    let vm = MergeDrivesViewModel(drives: [first, second])
    let expected = 7200.0.localizedHoursMinutesString()
    #expect(vm.formattedTotalDuration == expected)
  }

  // MARK: - formattedTotalPositionCount

  @Test
  func formattedTotalPositionCountIsZeroWhenNeitherDriveHasPositions() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    #expect(vm.formattedTotalPositionCount == "0")
  }

  @Test
  func formattedTotalPositionCountSumsPositionsFromBothDrives() {
    let first = makeDrive(name: "First", startOffset: 0)
    first.positions = [makePosition(), makePosition()]
    let second = makeDrive(name: "Second", startOffset: 3600)
    second.positions = [makePosition()]
    let vm = MergeDrivesViewModel(drives: [first, second])
    #expect(vm.formattedTotalPositionCount == "3")
  }

  // MARK: - firstDisplay / secondDisplay

  @Test
  func firstDisplayFormattedDistanceMatchesDriveDistance() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    let expected = Measurement(value: first.distanceMetres, unit: UnitLength.meters).localizedDistanceString()
    #expect(vm.firstDisplay.formattedDistance == expected)
  }

  @Test
  func secondDisplayFormattedDistanceMatchesDriveDistance() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    let expected = Measurement(value: second.distanceMetres, unit: UnitLength.meters).localizedDistanceString()
    #expect(vm.secondDisplay.formattedDistance == expected)
  }

  @Test
  func firstDisplayDateTimeLabelContainsStartPlaceName() {
    let first = makeDrive(name: "First", startOffset: 0)
    first.startPlaceName = "Home"
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    #expect(vm.firstDisplay.dateTimeLabel.contains("Home"))
  }

  @Test
  func firstDisplayDateTimeLabelEqualsStartTimeLabelWhenNoStartPlace() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    let expectedLabel = DriveStatsPresenter(drive: first).startTimeLabel
    #expect(vm.firstDisplay.dateTimeLabel == expectedLabel)
  }

  @Test
  func firstDisplayFormattedDurationMatchesDriveDuration() {
    let first = makeDrive(name: "First", startOffset: 0, endOffset: 1800)
    let second = makeDrive(name: "Second", startOffset: 1800, endOffset: 3600)
    let vm = MergeDrivesViewModel(drives: [first, second])
    let expected = first.activeDurationSeconds.localizedHoursMinutesString()
    #expect(vm.firstDisplay.formattedDuration == expected)
  }

  // MARK: - Helpers

  private func makeDrive(name: String, startOffset: TimeInterval, endOffset: TimeInterval? = nil) -> Drive {
    let drive = Drive(name: name)
    drive.startedAt = Date(timeIntervalSinceReferenceDate: startOffset)
    drive.endedAt = endOffset.map { Date(timeIntervalSinceReferenceDate: $0) }
    return drive
  }

  private func makePosition() -> Position {
    Position(
      latitude: 51.5,
      longitude: -0.1,
      altitude: 10,
      horizontalAccuracy: 5,
      verticalAccuracy: 3,
      course: 0,
      courseAccuracy: 5,
      speed: 14,
      speedAccuracy: 1
    )
  }
}
