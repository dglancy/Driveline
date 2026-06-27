//
//  RecordingAvailabilityTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 27/06/2026.
//

@testable import Driveline
import Testing
import UIKit

@Suite("RecordingAvailability")
@MainActor
struct RecordingAvailabilityTests {

  @Test
  func padIsNotSupported() {
    #expect(!RecordingAvailability.isSupported(.pad))
  }

  @Test
  func phoneIsSupported() {
    #expect(RecordingAvailability.isSupported(.phone))
  }

  @Test
  func unspecifiedIsSupported() {
    #expect(RecordingAvailability.isSupported(.unspecified))
  }
}
