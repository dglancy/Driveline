//
//  Icons.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

enum Icons {

  enum Drive {
    static let morningDrive = "sunrise.fill"
    static let afternoonDrive = "sun.max.fill"
    static let eveningDrive = "sunset.fill"
    static let nightDrive = "moon.stars.fill"
    static let startMarker = "house.fill"
    static let finishFlag = "flag.pattern.checkered"
    static let finishFlagCircle = "flag.pattern.checkered.circle.fill"
    static let reorderDrives = "arrow.up.arrow.down"
  }

  enum Recording {
    static let stop = "stop.fill"
    static let battery = "battery.75percent"
  }

  enum Stats {
    static let speed = "gauge"
    static let location = "location"
    static let gpsSignal = "dot.radiowaves.left.and.right"
  }

  enum Navigation {
    static let chevronDown = "chevron.down"
    static let chevronRight = "chevron.right"
    static let chevronLeft = "chevron.left"
  }

  enum Options {
    static let ellipsis = "ellipsis"
    static let viewfinder = "viewfinder"
    static let sharing = "square.and.arrow.up"
  }

  enum Selection {
    static let selected = "checkmark.circle.fill"
    static let deselected = "circle"
    static let recordingActive = "circle.inset.filled"
  }

  enum Merging {
    static let merge = "arrow.triangle.merge"
  }

  enum Widgets {
    static let timer = "timer"
    static let car = "car.fill"
  }
  
  enum Panels {
    static let drives = "checkmark.circle"
    static let distance = "arrow.right"
  }
}
