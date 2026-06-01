//
//  Constants.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import CoreLocation
import os.log

// MARK: - App

let kAppName = "AutoRoute"
let kAppBundleId = "com.targatrips.AutoRoute"
let kGPXCreator = "AutoRoute for iOS"

// MARK: - Configuration

nonisolated let kMinimumLocationAccuracy: CLLocationAccuracy = 50
nonisolated let kMaxLocationAge: TimeInterval = 5
let kRouteAgeCutoff: TimeInterval = -86400
let kPauseTimeoutInterval: TimeInterval = 3 * 3600

// MARK: - Common strings

let kBlankString = ""
let kDashString = "—"

// MARK: - Testing

let kUITestingFlag = "-ui-testing"
