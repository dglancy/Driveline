//
//  LocationStreaming.swift
//  Driveline
//
//  Created by Damien Glancy on 15/06/2026.
//

import Foundation
import CoreLocation

// MARK: - Background Activity Session

protocol BackgroundActivitySession: AnyObject {
  func invalidate()
}

extension CLBackgroundActivitySession: BackgroundActivitySession {}

// MARK: - Background Activity Session Providing

@MainActor
protocol BackgroundActivitySessionProviding {
  func begin() -> any BackgroundActivitySession
}

struct SystemBackgroundActivitySessionProvider: BackgroundActivitySessionProviding {

  // MARK: - Functions

  func begin() -> any BackgroundActivitySession {
    CLBackgroundActivitySession()
  }
}

// MARK: - Location Streaming

@MainActor
protocol LocationStreaming {
  func locations() -> AsyncStream<CLLocation>
}

struct LiveLocationStreamProvider: LocationStreaming {

  // MARK: - Properties

  let configuration: CLLocationUpdate.LiveConfiguration

  // MARK: - Functions

  func locations() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
      let task = Task {
        do {
          for try await update in CLLocationUpdate.liveUpdates(configuration) {
            if let location = update.location {
              continuation.yield(location)
            }
          }
        } catch {
          Log.location.error("Live location updates ended: \(error.localizedDescription)")
        }
        continuation.finish()
      }
      continuation.onTermination = { _ in task.cancel() }
    }
  }
}

// MARK: - CLActivityType + LiveConfiguration

extension CLActivityType {

  var liveConfiguration: CLLocationUpdate.LiveConfiguration {
    switch self {
    case .automotiveNavigation: .automotiveNavigation
    case .otherNavigation: .otherNavigation
    case .fitness: .fitness
    case .airborne: .airborne
    default: .default
    }
  }
}
