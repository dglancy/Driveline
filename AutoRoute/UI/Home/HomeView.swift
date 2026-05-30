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
      if let summary = viewModel.summaryLine {
        Section {
          Text(summary)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 4, trailing: 20))
        }
        .listSectionSeparator(.hidden)
        .listSectionSpacing(0)
      }

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
    .contentMargins(.top, 0, for: .scrollContent)
    .navigationDestination(for: Route.self) { route in
      RouteDetailView(route: route)
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: Route.self, configurations: config) // swiftlint:disable:this force_try
  let context = container.mainContext
  let calendar = Calendar.current
  let now = Date.now

  func date(daysAgo: Int, hour: Int, minute: Int = 0) -> Date {
    let day = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
    return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
  }

  func pos(lat: Double, lon: Double, at timestamp: Date) -> Position {
    let position = Position(
      timestamp: timestamp,
      latitude: lat, longitude: lon,
      altitude: 50, horizontalAccuracy: 5, verticalAccuracy: 3,
      course: 0, courseAccuracy: 5, speed: 14, speedAccuracy: 1
    )
    context.insert(position)
    return position
  }

  typealias Coords = (lat: Double, lon: Double)
  let home: Coords = (51.440, -0.102)

  let samples: [(name: String, daysAgo: Int, hour: Int, minute: Int, duration: TimeInterval?,
                 place: String?, end: Coords?)] = [
                  ("Morning Commute", 0, 8, 12, 1_740, "Home", (51.514, -0.093)),
                  ("School Run", 0, 15, 30, nil, nil, nil),
                  ("Evening Errand", 1, 18, 45, 1_200, "Tesco Extra", (51.452, -0.091)),
                  ("Lunch Drive", 3, 12, 20, 2_100, nil, (51.459, -0.119)),
                  ("School Run", 3, 8, 10, 840, "School", (51.549, -0.122)),
                  ("Weekend Road Trip", 6, 10, 0, 14_400, "Brighton", (50.820, -0.142)),
                  ("City Centre Visit", 32, 11, 30, 2_700, "Manchester", (53.480, -2.244)),
                  ("Mountain Drive", 68, 9, 0, 10_800, "Snowdonia", (53.120, -4.131))
                 ]

  for (name, daysAgo, hour, minute, duration, place, end) in samples {
    let route = Route(name: name)
    route.startedAt = date(daysAgo: daysAgo, hour: hour, minute: minute)
    route.startPlaceName = place
    if let duration {
      route.endedAt = route.startedAt.addingTimeInterval(duration)
      route.isRecording = false
    }
    context.insert(route)
    route.positions.append(pos(lat: home.lat, lon: home.lon, at: route.startedAt))
    if let end {
      let endTime = route.endedAt ?? route.startedAt.addingTimeInterval(1_800)
      route.positions.append(pos(lat: end.lat, lon: end.lon, at: endTime))
    }
  }

  return HomeView()
    .modelContainer(container)
}
