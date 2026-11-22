//
//  IconsTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 22/11/2026.
//

@testable import Driveline
import Testing

@Suite("Icons")
@MainActor
struct IconsTests {

  // MARK: - Drive Detail Stats

  @Test
  func driveDetailMetadataIconsUseExpectedSymbols() {
    #expect(Icons.Stats.category == "tag")
    #expect(Icons.Stats.speed == "gauge")
    #expect(Icons.Stats.location == "location")
    #expect(Icons.Stats.gpsSignal == "antenna.radiowaves.left.and.right")
    #expect(Icons.Stats.startedBy == "timer")
  }
}
