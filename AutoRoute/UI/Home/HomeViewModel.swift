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

  // MARK: - Methods

  func update(with routes: [Route]) {
    sections = buildSections(from: routes)
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

  private func sectionTitle(for date: Date, today: Date, calendar: Calendar) -> String {
    let routeDay = calendar.startOfDay(for: date)
    let daysDiff = calendar.dateComponents([.day], from: routeDay, to: today).day ?? 0

    switch daysDiff {
    case 0:
      return "Today"
    case 1:
      return "Yesterday"
    case 2...6:
      return date.formatted(.dateTime.weekday(.wide))
    default:
      return date.formatted(.dateTime.month(.wide).year())
    }
  }
}
