//
//  RouteDetailViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

// MARK: - ExportedFile

struct ExportedFile: Identifiable {
  let id = UUID()
  let url: URL
}

// MARK: - RouteDetailViewModel

@MainActor
@Observable
final class RouteDetailViewModel {

  // MARK: - Properties

  var showSharingDialog = false
  var showingFullScreenMap = false
  var exportedFile: ExportedFile?
  var exportError: String?

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
    let kb = max(1, route.positions.count * 180 / 1024)
    return String(localized: "\(kb) KB", comment: "File size in kilobytes")
  }

  var gpxFilename: String {
    route.name.components(separatedBy: .whitespaces).joined(separator: kDashString) + ".gpx"
  }

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
  }

  // MARK: - Actions

  func shareRouteGPX() {
    Task {
      do {
        let url = try await ExportRouteGPX().export(route: route)
        exportedFile = ExportedFile(url: url)
      } catch {
        exportError = error.localizedDescription
      }
    }
  }

  func shareRoutePNG() {
    Task {
      do {
        let url = try await ExportRoutePNG().export(route: route)
        exportedFile = ExportedFile(url: url)
      } catch {
        exportError = error.localizedDescription
      }
    }
  }
}
