//
//  EditDriveViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class EditDriveViewModel {

  // MARK: - Properties

  var driveName: String
  var startPlaceName: String
  var endPlaceName: String

  @ObservationIgnored private let drive: Drive

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
    self.driveName = drive.name ?? ""
    self.startPlaceName = drive.startPlaceName ?? ""
    self.endPlaceName = drive.endPlaceName ?? ""
  }

  // MARK: - Actions

  func save() {
    let trimmedName = driveName.trimmingCharacters(in: .whitespaces)
    drive.name = trimmedName.isEmpty ? nil : trimmedName
    let trimmedStart = startPlaceName.trimmingCharacters(in: .whitespaces)
    drive.startPlaceName = trimmedStart.isEmpty ? nil : trimmedStart
    let trimmedEnd = endPlaceName.trimmingCharacters(in: .whitespaces)
    drive.endPlaceName = trimmedEnd.isEmpty ? nil : trimmedEnd
  }
}
