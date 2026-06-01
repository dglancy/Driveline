//
//  RouteDetailViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import CoreLocation
import Foundation
import MapKit
import Observation
import SwiftData
import SwiftUI

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
  var showingMoreMenu = false
  var showingDeleteConfirmation = false
  var showingEditRoute = false
  var exportedFile: ExportedFile?
  var exportError: String?

  @ObservationIgnored let route: Route
  @ObservationIgnored private let stats: RouteStatsPresenter

  // MARK: - Computed Properties

  var name: String { route.name }

  var dateString: String { route.startedAt.longDateString() }

  var distanceValue: String { stats.distanceValue }
  var distanceUnit: String { stats.distanceUnit }
  var durationValue: String { stats.durationValue }
  var durationUnit: String { stats.durationUnit }
  var avgSpeedValue: String { stats.avgSpeedValue }
  var avgSpeedUnit: String { stats.avgSpeedUnit }

  var startPlace: String? { route.startPlaceName }
  var endPlace: String? { route.endPlaceName }

  var departureTime: String { route.startedAt.clockString() }
  var arrivalTime: String? { route.endedAt?.clockString() }

  var topSpeed: String { Measurement(value: route.maxSpeedMetresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedString() }
  var trackPoints: String { route.positions.count.formatted() }
  var triggerDisplayName: String { route.trigger.displayName }

  var coordinates: [CLLocationCoordinate2D] {
    route.orderedPositions.map {
      CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
    }
  }

  var cameraPosition: MapCameraPosition {
    .fit(to: coordinates, paddingMultiplier: 1.5)
  }

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
    self.stats = RouteStatsPresenter(route: route)
  }

  // MARK: - Actions

  func deleteRoute(using context: ModelContext) {
    context.delete(route)
  }

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
