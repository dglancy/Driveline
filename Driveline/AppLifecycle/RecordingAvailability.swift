//
//  RecordingAvailability.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import UIKit

enum RecordingAvailability {
  static func isSupported(_ idiom: UIUserInterfaceIdiom) -> Bool {
    idiom != .pad
  }
}
