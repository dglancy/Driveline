//
//  DriveRowDisplay.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

import Foundation

struct DriveRowDisplay {
  let dateTimeLabel: String
  let formattedDistance: String
  let formattedDuration: String?
  let iconName: String

  static func iconName(for date: Date) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    switch hour {
    case 5..<12: return Icons.Drive.morningDrive
    case 12..<17: return Icons.Drive.afternoonDrive
    case 17..<21: return Icons.Drive.eveningDrive
    default: return Icons.Drive.nightDrive
    }
  }
}
