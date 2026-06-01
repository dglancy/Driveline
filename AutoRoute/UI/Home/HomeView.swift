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
            viewModel.exitSelectMode()
          }
          showingRecordingScreen = isRecording
        }
    }
    .fullScreenCover(isPresented: $showingRecordingScreen) {
      RecordingView(routeService: routeService)
    }
    .alert(
      String(localized: "Delete Routes", comment: "Delete confirmation alert title"),
      isPresented: $viewModel.showingDeleteConfirmation
    ) {
      Button(String(localized: "Delete", comment: "Confirm delete routes"), role: .destructive) {
        let selected = viewModel.selectedRoutes(from: viewModel.sections)
        viewModel.exitSelectMode()
        viewModel.deleteRoutes(selected, using: modelContext)
      }
      Button(String(localized: "Cancel", comment: "Cancel delete routes"), role: .cancel) { }
    } message: {
      Text(viewModel.deleteConfirmationMessage)
    }
    .alert(
      String(localized: "Couldn't Start Recording", comment: "Start route failure alert title"),
      isPresented: $viewModel.showingStartRouteError
    ) {
      Button(String(localized: "OK", comment: "Dismiss start route error alert"), role: .cancel) { }
    } message: {
      Text(viewModel.startRouteErrorMessage ?? "")
    }
    .sheet(isPresented: $showingMergeSheet) {
      if routesToMerge.count == 2 {
        MergeRoutesView(routes: routesToMerge) { orderedRoutes, mergedName in
          showingMergeSheet = false
          viewModel.mergeRoutes(orderedRoutes: orderedRoutes, mergedName: mergedName, using: modelContext)
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
            ForEach(section.rows) { row in
              if viewModel.isSelectMode {
                Button {
                  viewModel.toggleSelection(for: row.route.id)
                } label: {
                  RouteRowView(display: row.display, isSelected: viewModel.selectedRouteIDs.contains(row.route.id))
                }
                .buttonStyle(.plain)
              } else {
                NavigationLink(value: row.route) {
                  RouteRowView(display: row.display)
                    .opacity(routeService.isRecording ? 0.4 : 1)
                }
                .disabled(routeService.isRecording)
              }
            }
            .onDelete(perform: viewModel.isSelectMode ? nil : { indexSet in
              viewModel.deleteRoutes(at: indexSet, in: section, using: modelContext)
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
            viewModel.startRoute(using: routeService)
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
        .accessibilityLabel(
          routeService.isRecording
            ? String(localized: "Currently recording — open recording screen", comment: "Record button when recording")
            : String(localized: "Start a new route", comment: "Record button when idle")
        )
      }
    }
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
          PulsingDot(color: .red, size: 10)
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
            .accessibilityHidden(true)
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

// MARK: - Preview

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: Route.self, configurations: config) // swiftlint:disable:this force_try
  PreviewSampleData.insertSampleRoutes(in: container.mainContext)

  let locationService = LocationService()
  let locationDataRecorder = LocationDataRecorderService(locationService: locationService, modelContext: container.mainContext)
  let routeService = RouteService(modelContext: container.mainContext, locationService: locationService, locationDataRecorder: locationDataRecorder)

  return HomeView()
    .modelContainer(container)
    .environment(routeService)
}
