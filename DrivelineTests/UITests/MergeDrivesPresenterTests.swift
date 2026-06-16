//
//  MergeDrivesPresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 16/06/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("MergeDrivesPresenter")
@MainActor
struct MergeDrivesPresenterTests {

  // MARK: - defaultMergedName

  @Test
  func defaultMergedNameCombinesBothDriveDisplayNames() {
    let first = makeDrive(name: "Morning Commute", startOffset: 0)
    let second = makeDrive(name: "Evening Drive", startOffset: 3600)
    #expect(MergeDrivesPresenter.defaultMergedName(for: [first, second]) == "Morning Commute + Evening Drive")
  }

  // MARK: - formattedTotalDistance

  @Test
  func formattedTotalDistanceIsZeroWhenNeitherDriveHasPositions() {
    let presenter = makePresenter()
    let expected = Measurement(value: 0.0, unit: UnitLength.meters).localizedDistanceString()
    #expect(presenter.formattedTotalDistance == expected)
  }

  // MARK: - formattedTotalDuration

  @Test
  func formattedTotalDurationSumsBothDriveDurations() {
    let first = makeDrive(name: "First", startOffset: 0, endOffset: 3600)
    let second = makeDrive(name: "Second", startOffset: 3600, endOffset: 7200)
    let presenter = MergeDrivesPresenter(drives: [first, second])
    let expected = 7200.0.localizedHoursMinutesString()
    #expect(presenter.formattedTotalDuration == expected)
  }

  // MARK: - formattedTotalPositionCount

  @Test
  func formattedTotalPositionCountIsZeroWhenNeitherDriveHasPositions() {
    let presenter = makePresenter()
    #expect(presenter.formattedTotalPositionCount == "0")
  }

  @Test
  func formattedTotalPositionCountSumsPositionsFromBothDrives() {
    let first = makeDrive(name: "First", startOffset: 0)
    first.positions = [makePosition(), makePosition()]
    let second = makeDrive(name: "Second", startOffset: 3600)
    second.positions = [makePosition()]
    let presenter = MergeDrivesPresenter(drives: [first, second])
    #expect(presenter.formattedTotalPositionCount == "3")
  }

  // MARK: - firstDisplay / secondDisplay

  @Test
  func firstDisplayDateTimeLabelContainsStartPlaceName() {
    let first = makeDrive(name: "First", startOffset: 0)
    first.startPlaceName = "Home"
    let second = makeDrive(name: "Second", startOffset: 3600)
    let presenter = MergeDrivesPresenter(drives: [first, second])
    #expect(presenter.firstDisplay.dateTimeLabel.contains("Home"))
  }

  @Test
  func firstDisplayDateTimeLabelEqualsStartTimeLabelWhenNoStartPlace() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let presenter = MergeDrivesPresenter(drives: [first, second])
    let expectedLabel = DriveStatsPresenter(drive: first).startTimeLabel
    #expect(presenter.firstDisplay.dateTimeLabel == expectedLabel)
  }

  @Test
  func firstDisplayFormattedDurationMatchesDriveDuration() {
    let first = makeDrive(name: "First", startOffset: 0, endOffset: 1800)
    let second = makeDrive(name: "Second", startOffset: 1800, endOffset: 3600)
    let presenter = MergeDrivesPresenter(drives: [first, second])
    let expected = first.activeDurationSeconds.localizedHoursMinutesString()
    #expect(presenter.firstDisplay.formattedDuration == expected)
  }

  @Test
  func secondDisplayFormattedDistanceMatchesDriveDistance() {
    let first = makeDrive(name: "First", startOffset: 0)
    let second = makeDrive(name: "Second", startOffset: 3600)
    let presenter = MergeDrivesPresenter(drives: [first, second])
    let expected = Measurement(value: second.distanceMetres, unit: UnitLength.meters).localizedDistanceString()
    #expect(presenter.secondDisplay.formattedDistance == expected)
  }

  // MARK: - Helpers

  private func makePresenter() -> MergeDrivesPresenter {
    MergeDrivesPresenter(drives: [
      makeDrive(name: "First", startOffset: 0),
      makeDrive(name: "Second", startOffset: 3600)
    ])
  }

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
