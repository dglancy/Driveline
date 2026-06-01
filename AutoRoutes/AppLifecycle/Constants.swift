//
//  Constants.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation

// MARK: - App

let kAppName = "AutoRoutes"
let kAppBundleId = "com.targatrips.AutoRoutes"
let kGPXCreator = "AutoRoutes for iOS"

// MARK: - Configuration

nonisolated let kMinimumLocationAccuracy: CLLocationAccuracy = 50
nonisolated let kMaxLocationAge: TimeInterval = 5
let kRouteAgeCutoff: TimeInterval = -86400
let kPauseTimeoutInterval: TimeInterval = 30 * 60

// MARK: - Common strings

let kBlankString = ""
let kDashString = "—"

// MARK: - Testing

let kUITestingFlag = "-ui-testing"
