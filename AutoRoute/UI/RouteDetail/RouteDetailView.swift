//
//  RouteDetailView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import MapKit
import SwiftData
import SwiftUI

struct RouteDetailView: View {

  // MARK: - Properties

  @State private var viewModel: RouteDetailViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  private let mapHeight: CGFloat = 280

  // MARK: - Lifecycle

  init(route: Route) {
    _viewModel = State(initialValue: RouteDetailViewModel(route: route))
  }

  // MARK: - Body

  var body: some View {
    ZStack(alignment: .top) {
      Color(.systemGroupedBackground)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        RouteDetailMapView(route: viewModel.route)
          .frame(height: mapHeight)
          .overlay(alignment: .topLeading) {
            glassButton(systemImage: "chevron.left") { dismiss() }
              .padding(14)
          }
          .overlay(alignment: .topTrailing) {
            glassButton(systemImage: "ellipsis") {
              viewModel.showingMoreMenu = true
            }
            .padding(14)
          }
          .overlay(alignment: .bottomTrailing) {
            glassButton(systemImage: "viewfinder") {
              viewModel.showingFullScreenMap = true
            }
            .padding(14)
          }

        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            routeHeader
            statTiles
            endpointsCard
            metadataCard
            shareRouteButton
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 24)
        }
        .padding(.top, 20)
        .contentMargins(.top, 0, for: .scrollContent)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .navigationDestination(isPresented: $viewModel.showingFullScreenMap) {
      FullScreenMapView(route: viewModel.route)
    }
    .sheet(item: $viewModel.exportedFile) { file in
      ActivityViewController(activityItems: [file.url])
    }
    .alert(
      String(localized: "Export Failed", comment: "Export error alert title"),
      isPresented: Binding(get: { viewModel.exportError != nil }, set: { if !$0 { viewModel.exportError = nil } }),
      presenting: viewModel.exportError
    ) { _ in
      Button(String(localized: "OK", comment: "Dismiss export error alert")) { viewModel.exportError = nil }
    } message: { error in
      Text(error)
    }
    .alert(
      String(localized: "Delete Route", comment: "Delete confirmation alert title"),
      isPresented: $viewModel.showingDeleteConfirmation
    ) {
      Button(String(localized: "Delete", comment: "Confirm delete route"), role: .destructive) {
        modelContext.delete(viewModel.route)
        dismiss()
      }
      Button(String(localized: "Cancel", comment: "Cancel delete route"), role: .cancel) { }
    } message: {
      Text(String(localized: "This route and all its data will be permanently deleted.", comment: "Delete route confirmation message"))
    }
    .sheet(isPresented: $viewModel.showingEditRoute) {
      EditRouteView(route: viewModel.route)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .overlay {
      if viewModel.showingMoreMenu {
        Color.black.opacity(0.35)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
              viewModel.showingMoreMenu = false
            }
          }
          .transition(.opacity)
      }
    }
    .overlay(alignment: .bottom) {
      if viewModel.showingMoreMenu {
        moreMenuActionSheet
          .padding(.horizontal, 8)
          .padding(.bottom, 8)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.85), value: viewModel.showingMoreMenu)
  }

  // MARK: - Private Views

  private var routeHeader: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(viewModel.name)
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(Color(.label))
      Text(viewModel.dateString)
        .font(.system(size: 15))
        .foregroundStyle(.secondary)
    }
  }

  private var statTiles: some View {
    HStack(spacing: 10) {
      RouteStatTile(
        icon: "ruler",
        label: String(localized: "Distance", comment: "Stat tile label"),
        value: viewModel.distanceValue,
        unit: viewModel.distanceUnit
      )
      RouteStatTile(
        icon: "clock",
        label: String(localized: "Duration", comment: "Stat tile label"),
        value: viewModel.durationValue,
        unit: String(localized: "active", comment: "Active duration (not including pauses)")
      )
      RouteStatTile(
        icon: "speedometer",
        label: String(localized: "Avg Speed", comment: "Stat tile label"),
        value: viewModel.avgSpeedValue,
        unit: viewModel.avgSpeedUnit
      )
    }
  }

  private var endpointsCard: some View {
    VStack(spacing: 0) {
      EndpointRow(
        isStart: true,
        place: viewModel.startPlace,
        subtitle: String(localized: "Departure", comment: "Endpoint row subtitle"),
        time: viewModel.departureTime
      )
      Divider().padding(.leading, 52)
      EndpointRow(
        isStart: false,
        place: viewModel.endPlace,
        subtitle: String(localized: "Arrival", comment: "Endpoint row subtitle"),
        time: viewModel.arrivalTime,
        isLast: true
      )
    }
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
  }

  private var metadataCard: some View {
    VStack(spacing: 0) {
      MetadataRow(icon: "gauge", title: String(localized: "Top Speed", comment: "Metadata row"), value: viewModel.topSpeed)
      Divider().padding(.leading, 52)
      MetadataRow(icon: "location", title: String(localized: "Track Points", comment: "Metadata row"), value: viewModel.trackPoints)
      Divider().padding(.leading, 52)
      MetadataRow(
        icon: "dot.radiowaves.left.and.right",
        title: String(localized: "Started by", comment: "Metadata row"),
        value: viewModel.triggerDisplayName
      )
      Divider().padding(.leading, 52)
      MetadataRow(icon: "doc", title: String(localized: "GPX File", comment: "Metadata row"), value: viewModel.gpxFileSize, isLast: true)
    }
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
  }

  private var shareRouteButton: some View {
    Button {
      viewModel.showSharingDialog = true
    } label: {
      Label(String(localized: "Share Route", comment: "Share button"), systemImage: "square.and.arrow.up")
        .font(.system(size: 17, weight: .medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    .alert(String(localized: "Share Route", comment: "Share route alert title"), isPresented: $viewModel.showSharingDialog) {
      Button(String(localized: "Share GPX", comment: "Share route as GPX")) { viewModel.shareRouteGPX() }
      Button(String(localized: "Share PNG", comment: "Share route as PNG")) { viewModel.shareRoutePNG() }
      Button(String(localized: "Cancel", comment: "Cancel share route"), role: .cancel) { }
    }
  }

  private var moreMenuActionSheet: some View {
    VStack(spacing: 8) {
      VStack(spacing: 0) {
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewModel.showingMoreMenu = false
          }
          viewModel.showingEditRoute = true
        } label: {
          Text(String(localized: "Edit Route Details", comment: "More menu action"))
            .font(.system(size: 20))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }

        Divider()

        Button(role: .destructive) {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewModel.showingMoreMenu = false
          }
          viewModel.showingDeleteConfirmation = true
        } label: {
          Text(String(localized: "Delete Route", comment: "More menu action"))
            .font(.system(size: 20))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
      }
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))

      Button {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
          viewModel.showingMoreMenu = false
        }
      } label: {
        Text(String(localized: "Cancel", comment: "More menu cancel"))
          .font(.system(size: 20, weight: .semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 18)
      }
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
  }

  private func glassButton(systemImage: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.primary)
        .frame(width: 38, height: 38)
        .background(.regularMaterial, in: Circle())
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
  }
}

// MARK: - Private Subviews

private struct ActivityViewController: UIViewControllerRepresentable {

  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct EndpointRow: View {

  // MARK: - Properties

  let isStart: Bool
  let place: String?
  let subtitle: String
  let time: String?
  var isLast: Bool = false

  // MARK: - Body

  var body: some View {
    HStack(spacing: 12) {
      leadingIcon
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 1) {
        Text(place ?? String(localized: "Unknown", comment: "Unknown place name"))
          .font(.system(size: 16))
        Text(subtitle)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }

      Spacer()

      if let time {
        Text(time)
          .font(.system(size: 15))
          .foregroundStyle(.secondary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  // MARK: - Private Views

  @ViewBuilder
  private var leadingIcon: some View {
    if isStart {
      Circle()
        .fill(Color.green)
        .frame(width: 13, height: 13)
        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
        .shadow(color: .black.opacity(0.15), radius: 1)
    } else {
      Image(systemName: "flag.pattern.checkered")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.red)
    }
  }
}

private struct MetadataRow: View {

  // MARK: - Properties

  let icon: String
  let title: String
  let value: String
  var isLast: Bool = false

  // MARK: - Body

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
        .frame(width: 24)

      Text(title)
        .font(.system(size: 16))

      Spacer()

      Text(value)
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
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

  func position(lat: Double, lon: Double, at timestamp: Date, speed: Double = 14) -> Position {
    let pos = Position(
      timestamp: timestamp,
      latitude: lat, longitude: lon,
      altitude: 50, horizontalAccuracy: 5, verticalAccuracy: 3,
      course: 0, courseAccuracy: 5, speed: speed, speedAccuracy: 1
    )
    context.insert(pos)
    return pos
  }

  let route = Route(name: "Weekend to Tahoe", trigger: .automatic)
  route.startedAt = date(daysAgo: 6, hour: 7, minute: 5)
  route.endedAt = route.startedAt.addingTimeInterval(3 * 3600 + 28 * 60)
  route.status = .finished
  route.startPlaceName = "Home · Sunnyvale"
  route.endPlaceName = "South Lake Tahoe"
  context.insert(route)

  let waypoints: [(Double, Double, Double)] = [
    (37.368, -122.036, 10), (37.450, -121.900, 22), (37.560, -121.750, 28),
    (37.700, -121.500, 31), (37.900, -121.200, 35), (38.100, -120.900, 30),
    (38.300, -120.500, 28), (38.560, -119.980, 15)
  ]
  for (index, (lat, lon, speed)) in waypoints.enumerated() {
    let interval = Double(index) * (3 * 3600 + 28 * 60) / Double(waypoints.count - 1)
    let timestamp = route.startedAt.addingTimeInterval(interval)
    route.positions.append(position(lat: lat, lon: lon, at: timestamp, speed: speed))
  }

  return NavigationStack {
    RouteDetailView(route: route)
  }
  .modelContainer(container)
}
