//
//  Constants.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation

// MARK: - App

let kAppBundleId = Bundle.main.bundleIdentifier!
let kGPXCreator = "Driveline for iOS"

// MARK: - Configuration

nonisolated let kMinimumLocationAccuracy: CLLocationAccuracy = 50
nonisolated let kMaxLocationAge: TimeInterval = 5
let kRouteAgeCutoff: TimeInterval = -86400
let kPauseTimeoutInterval: TimeInterval = 30 * 60

// MARK: - Common strings

let kDashString = "—"

// MARK: - Testing

let kUITestingFlag = "-ui-testing"
