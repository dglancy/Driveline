//
//  HomeViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation
import Observation

@Observable
final class HomeViewModel {

  // MARK: - Types

  struct RouteSection: Identifiable {
    var id: String { title }
    let title: String
    let routes: [Route]
  }

  // MARK: - Properties

  private(set) var sections: [RouteSection] = []
  private(set) var summaryLine: String?
  private(set) var isSelectMode: Bool = false
  private(set) var selectedRouteIDs: Set<UUID> = []
  var showingDeleteConfirmation: Bool = false

  // MARK: - Computed Properties

  var canMerge: Bool { selectedRouteIDs.count == 2 }
  var canDelete: Bool { !selectedRouteIDs.isEmpty }

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

  func enterSelectMode() {
    isSelectMode = true
    selectedRouteIDs = []
  }

  func exitSelectMode() {
    isSelectMode = false
    selectedRouteIDs = []
  }

  func toggleSelection(for id: UUID) {
    if selectedRouteIDs.contains(id) {
      selectedRouteIDs.remove(id)
    } else {
      selectedRouteIDs.insert(id)
    }
  }

  func selectedRoutes(from sections: [RouteSection]) -> [Route] {
    sections.flatMap(\.routes).filter { selectedRouteIDs.contains($0.id) }
  }

  func update(with routes: [Route]) {
    sections = buildSections(from: routes)
    summaryLine = buildSummaryLine(from: routes)
  }

  // MARK: - Private

  private func buildSections(from routes: [Route]) -> [RouteSection] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)

    var groupMap: [(key: String, routes: [Route])] = []

    for route in routes.sorted(by: { $0.startedAt > $1.startedAt }) {
      let key = sectionTitle(for: route.startedAt, today: today, calendar: calendar)
      if let index = groupMap.firstIndex(where: { $0.key == key }) {
        groupMap[index].routes.append(route)
      } else {
        groupMap.append((key: key, routes: [route]))
      }
    }

    return groupMap.map { RouteSection(title: $0.key, routes: $0.routes) }
  }

  private func buildSummaryLine(from routes: [Route]) -> String? {
    let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
    let recent = routes.filter { $0.startedAt >= cutoff }
    guard !recent.isEmpty else { return nil }
    let totalMetres = recent.reduce(0.0) { $0 + $1.distanceMetres }
    let count = recent.count
    let distance = totalMetres.localizedDistanceString()
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
      return date.formatted(.dateTime.weekday(.wide))
    default:
      return date.formatted(.dateTime.month(.wide).year())
    }
  }
}
