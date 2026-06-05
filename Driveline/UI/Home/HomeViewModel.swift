//
//  HomeViewModel.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class HomeViewModel {

  // MARK: - Types

  struct RouteRow: Identifiable {
    let route: Route
    let display: RouteRowDisplay
    var id: UUID { route.id }
  }

  struct RouteSection: Identifiable {
    var id: String { title }
    let title: String
    let rows: [RouteRow]
  }

  // MARK: - Properties

  private(set) var sections: [RouteSection] = []
  private(set) var summaryLine: String?
  private(set) var isSelectMode: Bool = false
  private(set) var selectedRouteIDs: Set<UUID> = []
  private(set) var startRouteErrorMessage: String?
  private(set) var routesToMerge: [Route] = []

  var showingDeleteConfirmation: Bool = false
  var showingStartRouteError: Bool = false
  var showingRecordingScreen: Bool = false
  var showingMergeSheet: Bool = false

  // MARK: - Computed Properties

  var canMerge: Bool { selectedRouteIDs.count == 2 }
  var canDelete: Bool { !selectedRouteIDs.isEmpty }

  var deleteConfirmationMessage: String {
    if selectedRouteIDs.count == 1 {
      return String(
        localized: "This route and all its data will be permanently deleted.",
        comment: "Delete single route confirmation message"
      )
    } else {
      return String(
        localized: "These \(selectedRouteIDs.count) routes and all their data will be permanently deleted.",
        comment: "Delete multiple routes confirmation message"
      )
    }
  }

  var selectionCountText: String {
    if selectedRouteIDs.isEmpty {
      return String(localized: "Select 2 routes to merge", comment: "Multiselect placeholder when nothing is selected")
    }
    return String(
      localized: "\(selectedRouteIDs.count) selected",
      comment: "Multiselect count of selected routes"
    )
  }

  // MARK: - Methods

  func startRoute(trigger: Route.RecordingTrigger = .manual, using routeService: RouteService) {
    do {
      try routeService.startRoute(trigger: trigger)
    } catch {
      startRouteErrorMessage = error.localizedDescription
      showingStartRouteError = true
    }
  }

  func enterSelectMode() {
    isSelectMode = true
    selectedRouteIDs = []
  }

  func exitSelectMode() {
    isSelectMode = false
    selectedRouteIDs = []
  }

  func triggerMerge() {
    routesToMerge = selectedRoutes(from: sections).sorted { $0.startedAt < $1.startedAt }
    showingMergeSheet = true
  }

  func toggleSelection(for id: UUID) {
    if selectedRouteIDs.contains(id) {
      selectedRouteIDs.remove(id)
    } else {
      selectedRouteIDs.insert(id)
    }
  }

  func selectedRoutes(from sections: [RouteSection]) -> [Route] {
    sections.flatMap(\.rows).map(\.route).filter { selectedRouteIDs.contains($0.id) }
  }

  func update(with routes: [Route]) {
    sections = buildSections(from: routes)
    summaryLine = buildSummaryLine(from: routes)
  }

  func deleteRoutes(_ routes: [Route], using context: ModelContext) {
    for route in routes {
      context.delete(route)
    }
  }

  func deleteRoutes(at indexSet: IndexSet, in section: RouteSection, using context: ModelContext) {
    deleteRoutes(indexSet.map { section.rows[$0].route }, using: context)
  }

  func mergeRoutes(orderedRoutes: [Route], mergedName: String, using context: ModelContext) {
    guard orderedRoutes.count == 2 else { return }
    let first = orderedRoutes[0]
    let second = orderedRoutes[1]

    let merged = Route(name: mergedName)
    merged.startedAt = first.startedAt
    merged.endedAt = second.endedAt ?? first.endedAt
    merged.status = .finished
    merged.startPlaceName = first.startPlaceName
    merged.endPlaceName = second.endPlaceName
    merged.positions = first.positions + second.positions

    context.insert(merged)
    context.delete(first)
    context.delete(second)
  }

  // MARK: - Private

  private func buildSections(from routes: [Route]) -> [RouteSection] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    var groupMap: [(key: String, rows: [RouteRow])] = []

    for route in routes.sorted(by: { $0.startedAt > $1.startedAt }) {
      let key = sectionTitle(for: route.startedAt, today: today, calendar: calendar)
      let row = RouteRow(route: route, display: makeDisplay(for: route))
      if let index = groupMap.firstIndex(where: { $0.key == key }) {
        groupMap[index].rows.append(row)
      } else {
        groupMap.append((key: key, rows: [row]))
      }
    }

    return groupMap.map { RouteSection(title: $0.key, rows: $0.rows) }
  }

  private func makeDisplay(for route: Route) -> RouteRowDisplay {
    let duration = route.endedAt != nil ? route.activeDurationSeconds.localizedHoursMinutesString() : nil
    let distance = Measurement(value: route.distanceMetres, unit: UnitLength.meters)
    return RouteRowDisplay(
      name: route.name,
      dateTimeLabel: RouteStatsPresenter(route: route).startTimeLabel,
      formattedDistance: distance.localizedDistanceString(),
      formattedDuration: duration
    )
  }

  private func buildSummaryLine(from routes: [Route]) -> String? {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
    let recent = routes.filter { $0.startedAt >= cutoff }
    guard !recent.isEmpty else { return nil }
    let totalMetres = recent.reduce(0.0) { $0 + $1.distanceMetres }
    let count = recent.count
    let distance = Measurement(value: totalMetres, unit: UnitLength.meters).localizedDistanceString()
    if count == 1 {
      return String(
        localized: "\(count) route · \(distance) in the last 30 days",
        comment: "Home screen summary (singular): one route and total distance over the last 30 days"
      )
    } else {
      return String(
        localized: "\(count) routes · \(distance) in the last 30 days",
        comment: "Home screen summary (plural): number of routes and total distance over the last 30 days"
      )
    }
  }

  private func sectionTitle(for date: Date, today: Date, calendar: Calendar) -> String {
    let routeDay = calendar.startOfDay(for: date)
    let daysDiff = calendar.dateComponents([.day], from: routeDay, to: today).day ?? 0

    switch daysDiff {
    case 0:
      return String(localized: "Today")
    case 1:
      return String(localized: "Yesterday")
    case 2...6:
      return date.weekdayName()
    default:
      return date.monthAndYear()
    }
  }
}
