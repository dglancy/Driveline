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
  var shouldThrow = false

  func startRecording(with drive: Drive) throws {
    if shouldThrow { throw MockRecorderError.startFailed }
    self.drive = drive
  }

  func stopRecording() {
    drive = nil
  }
}

enum MockRecorderError: Error {
  case startFailed
}
