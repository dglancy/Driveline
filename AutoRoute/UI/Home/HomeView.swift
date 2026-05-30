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
  @EnvironmentObject private var routeService: RouteService
  @Query(sort: \Route.startedAt, order: .reverse) private var routes: [Route]
  @State private var viewModel = HomeViewModel()
  @State private var showingRecordingScreen = false

  // MARK: - Body

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Routes")
        .toolbar { recordButton }
        .onChange(of: routes, initial: true) { _, newRoutes in
          viewModel.update(with: newRoutes)
        }
        .onChange(of: routeService.isRecording) { _, isRecording in
          if isRecording {
            showingRecordingScreen = true
          } else {
            showingRecordingScreen = false
          }
        }
    }
    .fullScreenCover(isPresented: $showingRecordingScreen) {
      RecordingView()
        .environmentObject(routeService)
    }
  }

  // MARK: - Private Views

  @ViewBuilder
  private var content: some View {
    if viewModel.sections.isEmpty && !routeService.isRecording {
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
      if routeService.isRecording {
        recordingBanner
      }

      if let summary = viewModel.summaryLine {
        Section {
          Text(summary)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .listRowBackground(Color.clear)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .listSectionSpacing(0)
      }

      ForEach(viewModel.sections) { section in
        Section(section.title) {
          ForEach(section.routes) { route in
            NavigationLink(value: route) {
              RouteRowView(route: route)
                .opacity(routeService.isRecording ? 0.4 : 1)
            }
            .disabled(routeService.isRecording)
          }
        }
      }
    }
    .contentMargins(.top, 0, for: .scrollContent)
    .navigationDestination(for: Route.self) { route in
      RouteDetailView(route: route)
    }
  }

  @ViewBuilder
  private var recordingBanner: some View {
    Section {
      Button {
        showingRecordingScreen = true
      } label: {
        HStack(spacing: 12) {
          RecordingDot()
          VStack(alignment: .leading, spacing: 1) {
            Text("Recording drive…")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Color(.label))
            Text("\(routeService.route?.trigger.displayName ?? "") · Tap to view")
              .font(.system(size: 13.5))
              .foregroundStyle(Color(.secondaryLabel))
          }
          Spacer()
          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.vertical, 4)
      }
      .buttonStyle(.plain)
      .listRowBackground(Color.red.opacity(0.08))
    }
    .listSectionSeparator(.hidden)
  }

  @ToolbarContentBuilder
  private var recordButton: some ToolbarContent {
    ToolbarItem(placement: .topBarTrailing) {
      Button {
        if routeService.isRecording {
          showingRecordingScreen = true
        } else {
          routeService.startRoute()
        }
      } label: {
        ZStack {
          Circle().fill(Color(.systemFill))
          if routeService.isRecording {
            RoundedRectangle(cornerRadius: 3)
              .fill(.red)
              .frame(width: 11, height: 11)
          } else {
            Image(systemName: "circle.inset.filled")
              .font(.system(size: 22))
              .foregroundStyle(.red)
          }
        }
        .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
    }
  }
}

// MARK: - Subviews

private struct RecordingDot: View {

  // MARK: - Properties

  @State private var animating = false

  // MARK: - Body

  var body: some View {
    ZStack {
      Circle()
        .fill(Color.red)
        .scaleEffect(animating ? 2.0 : 1.0)
        .opacity(animating ? 0 : 0.4)
      Circle()
        .fill(Color.red)
    }
    .frame(width: 10, height: 10)
    .onAppear {
      withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
        animating = true
      }
    }
  }
}

// MARK: - Preview

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

  let locationService = LocationService()
  let locationDataRecorder = LocationDataRecorderService(locationService: locationService, modelContext: context)
  let routeService = RouteService(modelContext: context, locationService: locationService, locationDataRecorder: locationDataRecorder)

  return HomeView()
    .modelContainer(container)
    .environmentObject(routeService)
}
