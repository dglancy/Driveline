//
//  DriveEditor.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

enum DriveEditor {

  static func apply(name: String, startPlace: String, endPlace: String, to drive: Drive) {
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    drive.name = trimmedName.isEmpty ? nil : trimmedName
    let trimmedStart = startPlace.trimmingCharacters(in: .whitespaces)
    drive.startPlaceName = trimmedStart.isEmpty ? nil : trimmedStart
    let trimmedEnd = endPlace.trimmingCharacters(in: .whitespaces)
    drive.endPlaceName = trimmedEnd.isEmpty ? nil : trimmedEnd
  }
}
