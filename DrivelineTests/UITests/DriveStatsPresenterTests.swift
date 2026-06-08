//
//  DriveStatsPresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 08/06/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("DriveStatsPresenter")
@MainActor
struct DriveStatsPresenterTests {

  // MARK: - distanceValue / distanceUnit

  @Test
  func distanceValueMatchesMeasurementFormatter() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    let expected = Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceValueString()
    #expect(presenter.distanceValue == expected)
  }

  @Test
  func distanceUnitMatchesMeasurementFormatter() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    let expected = Measurement(value: drive.distanceMetres, unit: UnitLength.meters).localizedDistanceUnitSymbol()
    #expect(presenter.distanceUnit == expected)
  }

  // MARK: - durationValue / durationUnit

  @Test
  func durationValueMatchesDriveDuration() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    #expect(presenter.durationValue == drive.activeDurationSeconds.localizedHoursMinutesString())
  }

  @Test
  func durationUnitIsActive() {
    let presenter = DriveStatsPresenter(drive: makeDrive())
    #expect(presenter.durationUnit == "active")
  }

  // MARK: - avgSpeedValue / avgSpeedUnit

  @Test
  func avgSpeedValueMatchesMeasurementFormatter() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    let expected = Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString()
    #expect(presenter.avgSpeedValue == expected)
  }

  @Test
  func avgSpeedUnitMatchesMeasurementFormatter() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    let expected = Measurement(value: drive.avgSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedUnitSymbol()
    #expect(presenter.avgSpeedUnit == expected)
  }

  // MARK: - startTimeLabel

  @Test
  func startTimeLabelIsNotEmpty() {
    let presenter = DriveStatsPresenter(drive: makeDrive())
    #expect(!presenter.startTimeLabel.isEmpty)
  }

  @Test
  func startTimeLabelContainsFormattedDate() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    #expect(presenter.startTimeLabel.contains(drive.startedAt.abbreviatedMonthAndDay()))
  }

  @Test
  func startTimeLabelContainsFormattedTime() {
    let drive = makeDrive()
    let presenter = DriveStatsPresenter(drive: drive)
    #expect(presenter.startTimeLabel.contains(drive.startedAt.clockString()))
  }

  @Test
  func startTimeLabelContainsMiddleDotSeparator() {
    let presenter = DriveStatsPresenter(drive: makeDrive())
    #expect(presenter.startTimeLabel.contains("·"))
  }

  // MARK: - Helpers

  private func makeDrive() -> Drive {
    let drive = Drive(name: "Test Drive")
    drive.startedAt = Date(timeIntervalSinceReferenceDate: 0)
    drive.endedAt = Date(timeIntervalSinceReferenceDate: 3600)
    return drive
  }
}
