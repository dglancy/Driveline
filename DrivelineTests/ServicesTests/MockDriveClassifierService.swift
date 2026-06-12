//
//  MockDriveClassifierService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 12/06/2026.
//

@testable import Driveline
import Foundation

@MainActor
final class MockDriveClassifierService: DriveClassifierServiceProtocol {

  // MARK: - Properties

  var categoryToSet: Drive.Category = .urban
  private(set) var classifiedDrives: [Drive] = []

  // MARK: - DriveClassifierServiceProtocol

  func classify(_ drive: Drive) async {
    drive.category = categoryToSet
    classifiedDrives.append(drive)
  }
}
