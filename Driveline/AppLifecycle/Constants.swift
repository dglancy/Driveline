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
let kDriveAgeCutoff: TimeInterval = -86400

// MARK: - Common strings

let kDashString = "—"

// MARK: - Testing

let kUITestingFlag = "-ui-testing"
