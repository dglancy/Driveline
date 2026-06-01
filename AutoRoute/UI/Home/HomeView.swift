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
      Button.delete {
        let selected = viewModel.selectedRoutes(from: viewModel.sections)
        viewModel.exitSelectMode()
        viewModel.deleteRoutes(selected, using: modelContext)
      }
      Button.cancel()
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
          viewModel.mergeRoutes(orderedRoutes: orderedRoutes, mergedName: mergedName, using: modelContext)
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
              .font(.callout)
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
        Button.cancel { viewModel.exitSelectMode() }
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
              Image(systemName: SystemImage.recordingActive)
                .font(.title2)
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

// MARK: - Preview

#Preview {
  let container = PreviewSampleData.previewContainer()
  PreviewSampleData.insertSampleRoutes(in: container.mainContext)

  let locationService = LocationService()
  let locationDataRecorder = LocationDataRecorderService(locationService: locationService, modelContext: container.mainContext)
  let routeService = RouteService(modelContext: container.mainContext, locationService: locationService, locationDataRecorder: locationDataRecorder)

  return HomeView()
    .modelContainer(container)
    .environment(routeService)
}
