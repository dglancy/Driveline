//
//  RouteDetailViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class RouteDetailViewModel {

  // MARK: - Properties

  var showingShareSheet = false

  @ObservationIgnored let route: Route

  // MARK: - Computed Properties

  var name: String { route.name }

  var dateString: String {
    route.startedAt.formatted(.dateTime.weekday(.wide).month(.wide).day())
  }

  var distanceValue: String { route.distanceMetres.localizedDistanceValueString() }
  var distanceUnit: String { route.distanceMetres.localizedDistanceUnitSymbol() }

  var durationValue: String { route.activeDurationSeconds.localizedHoursMinutesString() }

  var avgSpeedValue: String { route.avgSpeedMetresPerSecond.localizedSpeedValueString() }
  var avgSpeedUnit: String { route.avgSpeedMetresPerSecond.localizedSpeedUnitSymbol() }

  var startPlace: String? { route.startPlaceName }
  var endPlace: String? { route.endPlaceName }

  var departureTime: String { route.startedAt.formatted(.dateTime.hour().minute()) }
  var arrivalTime: String? { route.endedAt?.formatted(.dateTime.hour().minute()) }

  var topSpeed: String { route.maxSpeedMetresPerSecond.localizedSpeedString() }
  var trackPoints: String { route.positions.count.formatted() }
  var triggerDisplayName: String { route.trigger.displayName }
  var gpxFileSize: String {
    String(localized: "\(route.estimatedGPXFileSizeKB) KB", comment: "File size in kilobytes")
  }

  var gpxFilename: String {
    route.name.components(separatedBy: .whitespaces).joined(separator: kDashString) + ".gpx"
  }

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
  }
}
