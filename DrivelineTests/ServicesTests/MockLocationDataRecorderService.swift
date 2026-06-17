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

  var drive: Drive?

  func startRecording(with drive: Drive) {
    self.drive = drive
  }

  func stopRecording() {
    drive = nil
  }
}
