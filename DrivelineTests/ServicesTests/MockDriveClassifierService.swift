//
//  MockDriveClassifierService.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 12/06/2026.
//

@testable import Driveline
import Foundation

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
