//
//  MockLocationDataRecorderService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 08/06/2026.
//

@testable import Driveline
import Foundation

@MainActor
final class MockLocationDataRecorderService: LocationDataRecorderServiceProtocol {

  // MARK: - Properties

  var drive: Drive?

  // MARK: - Actions

  func startRecording(with drive: Drive) {
    self.drive = drive
  }

  func stopRecording() {
    drive = nil
  }
}
