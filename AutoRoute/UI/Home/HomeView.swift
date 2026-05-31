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
  @Environment(RouteService.self) private var routeService
  @Query(sort: \Route.startedAt, order: .reverse) private var routes: [Route]
  @State private var viewModel = HomeViewModel()
  @State private var showingRecordingScreen = false
  @State private var recordingViewModel: RecordingViewModel?
  @State private var showingMergeSheet = false
  @State private var routesToMerge: [Route] = []

  // MARK: - Body

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Routes")
        .toolbar { toolbarItems }
        .onChange(of: routes, initial: true) { _, newRoutes in
          viewModel.update(with: newRoutes)
        }
        .onChange(of: routeService.isRecording, initial: true) { _, isRecording in
          if isRecording {
            recordingViewModel = RecordingViewModel(routeService: routeService)
            viewModel.exitSelectMode()
          } else {
            recordingViewModel = nil
          }
          showingRecordingScreen = isRecording
        }
    }
    .fullScreenCover(isPresented: $showingRecordingScreen) {
      if let recordingViewModel {
        RecordingView(viewModel: recordingViewModel)
      }
    }
    .alert(
      String(localized: "Delete Routes", comment: "Delete confirmation alert title"),
      isPresented: $viewModel.showingDeleteConfirmation
    ) {
      Button(String(localized: "Delete", comment: "Confirm delete routes"), role: .destructive) {
        let selected = viewModel.selectedRoutes(from: viewModel.sections)
        viewModel.exitSelectMode()
        deleteRoutes(selected)
      }
      Button(String(localized: "Cancel", comment: "Cancel delete routes"), role: .cancel) { }
    } message: {
      let count = viewModel.selectedRouteIDs.count
      if count == 1 {
        Text(String(localized: "This route and all its data will be permanently deleted.",
                    comment: "Delete single route confirmation message"))
      } else {
        Text(String(localized: "These \(count) routes and all their data will be permanently deleted.",
                    comment: "Delete multiple routes confirmation message"))
      }
    }
    .sheet(isPresented: $showingMergeSheet) {
      if routesToMerge.count == 2 {
        MergeRoutesView(routes: routesToMerge) { orderedRoutes, mergedName in
          showingMergeSheet = false
          mergeRoutes(orderedRoutes: orderedRoutes, mergedName: mergedName)
        } onCancel: {
          showingMergeSheet = false
        }
      }
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
    ZStack(alignment: .bottom) {
      List {
        if routeService.isRecording {
          RecordingBannerSection(triggerDisplayName: routeService.route?.trigger.displayName) {
            showingRecordingScreen = true
          }
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
              if viewModel.isSelectMode {
                Button {
                  viewModel.toggleSelection(for: route.id)
                } label: {
                  RouteRowView(route: route, isSelected: viewModel.selectedRouteIDs.contains(route.id))
                }
                .buttonStyle(.plain)
              } else {
                NavigationLink(value: route) {
                  RouteRowView(route: route)
                    .opacity(routeService.isRecording ? 0.4 : 1)
                }
                .disabled(routeService.isRecording)
              }
            }
            .onDelete(perform: viewModel.isSelectMode ? nil : { indexSet in
              deleteRoutes(at: indexSet, in: section)
            })
          }
        }

        if viewModel.isSelectMode {
          Color.clear
            .frame(height: 70)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
      }
      .contentMargins(.top, 0, for: .scrollContent)
      .navigationDestination(for: Route.self) { route in
        RouteDetailView(route: route)
      }

      if viewModel.isSelectMode {
        SelectionToolbar(
          canMerge: viewModel.canMerge,
          canDelete: viewModel.canDelete,
          selectionCountText: viewModel.selectionCountText
        ) {
          let routes = viewModel.selectedRoutes(from: viewModel.sections)
          routesToMerge = routes.sorted { $0.startedAt < $1.startedAt }
          showingMergeSheet = true
        } onDelete: {
          viewModel.showingDeleteConfirmation = true
        }
      }
    }
  }

  // MARK: - Toolbar

  @ToolbarContentBuilder
  private var toolbarItems: some ToolbarContent {
    ToolbarItem(placement: .topBarLeading) {
      if viewModel.isSelectMode {
        Button(String(localized: "Cancel", comment: "Exit multiselect mode")) {
          viewModel.exitSelectMode()
        }
      } else {
        Button(String(localized: "Select", comment: "Enter multiselect mode")) {
          viewModel.enterSelectMode()
        }
        .disabled(routeService.isRecording)
      }
    }

    ToolbarItem(placement: .topBarTrailing) {
      if !viewModel.isSelectMode {
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

  // MARK: - Private Methods

  private func deleteRoutes(_ routes: [Route]) {
    for route in routes {
      modelContext.delete(route)
    }
  }

  private func deleteRoutes(at indexSet: IndexSet, in section: HomeViewModel.RouteSection) {
    deleteRoutes(indexSet.map { section.routes[$0] })
  }

  private func mergeRoutes(orderedRoutes: [Route], mergedName: String) {
    guard orderedRoutes.count == 2 else { return }
    let first = orderedRoutes[0]
    let second = orderedRoutes[1]

    let merged = Route(name: mergedName)
    merged.startedAt = first.startedAt
    merged.endedAt = second.endedAt ?? first.endedAt
    merged.status = .finished
    merged.trigger = .manual
    merged.startPlaceName = first.startPlaceName
    merged.endPlaceName = second.endPlaceName
    merged.positions = first.positions + second.positions

    modelContext.insert(merged)
    modelContext.delete(first)
    modelContext.delete(second)
  }
}

// MARK: - Subviews

private struct RecordingBannerSection: View {

  // MARK: - Properties

  let triggerDisplayName: String?
  let onTap: () -> Void

  // MARK: - Body

  var body: some View {
    Section {
      Button(action: onTap) {
        HStack(spacing: 12) {
          RecordingDot()
          VStack(alignment: .leading, spacing: 1) {
            Text("Recording drive…")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(Color(.label))
            if let triggerDisplayName {
              Text("\(triggerDisplayName) · Tap to view")
                .font(.system(size: 13.5))
                .foregroundStyle(Color(.secondaryLabel))
            } else {
              Text("Tap to view")
                .font(.system(size: 13.5))
                .foregroundStyle(Color(.secondaryLabel))
            }
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
}

private struct SelectionToolbar: View {

  // MARK: - Properties

  let canMerge: Bool
  let canDelete: Bool
  let selectionCountText: String
  let onMerge: () -> Void
  let onDelete: () -> Void

  // MARK: - Body

  var body: some View {
    HStack {
      Button(action: onMerge) {
        Label(
          String(localized: "Merge", comment: "Merge selected routes button"),
          systemImage: "arrow.triangle.merge"
        )
        .font(.system(size: 17, weight: .medium))
      }
      .disabled(!canMerge)
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(selectionCountText)
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)

      Button(String(localized: "Delete", comment: "Delete selected routes button"), action: onDelete)
        .font(.system(size: 17, weight: .medium))
        .foregroundStyle(canDelete ? Color.red : Color(.tertiaryLabel))
        .disabled(!canDelete)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.horizontal, 18)
    .padding(.top, 10)
    .padding(.bottom, 30)
    .background(.regularMaterial)
    .overlay(alignment: .top) {
      Divider()
    }
  }
}

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
      route.status = .finished
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
    .environment(routeService)
}
