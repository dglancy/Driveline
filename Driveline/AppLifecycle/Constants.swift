//
//  Constants.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation

// MARK: - App

let kGPXCreator = "Driveline for iOS"

// MARK: - Configuration

nonisolated let kMinimumLocationAccuracy: CLLocationAccuracy = 50
nonisolated let kMaxLocationAge: TimeInterval = 5
nonisolated let kDrivePlaceNameSweepCutoff: TimeInterval = -2_592_000 // 30 days
let kRecentDriveCutoff: TimeInterval = -1800
let kPlaceNameSweepTaskIdentifier = "com.targatrips.driveline.placename-sweep"

// MARK: - Common strings

let kDashString = "—"

// MARK: - Testing

let kUITestingFlag = "-ui-testing"
