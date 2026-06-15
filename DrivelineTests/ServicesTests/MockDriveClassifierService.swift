//
//  MockDriveClassifierService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 12/06/2026.
//

@testable import Driveline
import Foundation

// Test double: each test exercises it from a single sweep actor (or the main actor) at a time,
// never concurrently, so @unchecked Sendable is safe here.
final class MockDriveClassifierService: DriveClassifierServiceProtocol, @unchecked Sendable {

  // MARK: - Properties

  var categoryToSet: Drive.Category = .urban
  private(set) var classifiedInputs: [DriveClassificationInput] = []

  // MARK: - DriveClassifierServiceProtocol

  func classify(_ input: DriveClassificationInput) -> Drive.Category {
    classifiedInputs.append(input)
    return categoryToSet
  }
}
