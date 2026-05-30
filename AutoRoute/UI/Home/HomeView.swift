//
//  HomeView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {

  // MARK: - Properties

  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Route.startedAt, order: .reverse) private var routes: [Route]
  @State private var viewModel = HomeViewModel()

  // MARK: - Body

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Routes")
        .onChange(of: routes, initial: true) { _, newRoutes in
          viewModel.update(with: newRoutes)
        }
    }
  }

  // MARK: - Private Views

  @ViewBuilder
  private var content: some View {
    if viewModel.sections.isEmpty {
      emptyState
    } else {
      routeList
    }
  }

  private var emptyState: some View {
    ContentUnavailableView(
      "No Routes",
      systemImage: "car.fill",
      description: Text("Your recorded routes will appear here.")
    )
  }

  private var routeList: some View {
    List {
      ForEach(viewModel.sections) { section in
        Section(section.title) {
          ForEach(section.routes) { route in
            NavigationLink(value: route) {
              RouteRowView(route: route)
            }
          }
        }
      }
    }
    .navigationDestination(for: Route.self) { route in
      RouteDetailView(route: route)
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: Route.self, configurations: config)
  let context = container.mainContext
  let calendar = Calendar.current
  let now = Date.now

  func date(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
    let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
  }

  let samples: [(name: String, daysAgo: Int, hour: Int, minute: Int, duration: TimeInterval?, place: String?)] = [
    ("Morning Commute",    0,  8,  12, 1_740, "Home"),
    ("School Run",         0, 15,  30, nil,   nil),
    ("Evening Errand",     1, 18,  45, 1_200, "Tesco Extra"),
    ("Lunch Drive",        3,  12, 20, 2_100, nil),
    ("School Run",         3,   8, 10,   840, "School"),
    ("Weekend Road Trip",  6,  10,  0, 14_400, "Brighton"),
    ("City Centre Visit", 32,  11, 30,  2_700, "Manchester"),
    ("Mountain Drive",    68,   9,  0, 10_800, "Snowdonia"),
  ]

  for (name, daysAgo, hour, minute, duration, place) in samples {
    let route = Route(name: name)
    route.startedAt = date(daysAgo: daysAgo, hour: hour, minute: minute)
    route.startPlaceName = place
    if let duration {
      route.endedAt = route.startedAt.addingTimeInterval(duration)
      route.isRecording = false
    }
    context.insert(route)
  }

  return HomeView()
    .modelContainer(container)
}
