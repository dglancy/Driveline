//
//  FullScreenMapView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import MapKit
import SwiftData
import SwiftUI

struct FullScreenMapView: View {

  // MARK: - Properties

  @State private var viewModel: FullScreenMapViewModel

  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(route: Route) {
    _viewModel = State(initialValue: FullScreenMapViewModel(route: route))
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      Map(initialPosition: viewModel.cameraPosition) {
        if viewModel.coordinates.count > 1 {
          MapPolyline(coordinates: viewModel.coordinates)
            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        }

        if let start = viewModel.coordinates.first {
          Annotation("", coordinate: start, anchor: .center) {
            RouteStartAnnotation()
          }
        }

        if let end = viewModel.coordinates.last, viewModel.coordinates.count > 1 {
          Annotation("", coordinate: end, anchor: .bottom) {
            RouteEndAnnotation()
          }
        }
      }
      .mapStyle(.standard(emphasis: .muted))
      .ignoresSafeArea()

      VStack {
        HStack {
          GlassButton(systemImage: "chevron.left") { dismiss() }
          Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)

        Spacer()

        infoCard
          .padding(.horizontal, 16)
          .padding(.bottom, 32)
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

  // MARK: - Private Views

  private var infoCard: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(viewModel.name)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(Color(.label))

      HStack(spacing: 0) {
        statChip(value: viewModel.distanceValue, unit: viewModel.distanceUnit)
        Divider().frame(height: 28).padding(.horizontal, 12)
        statChip(value: viewModel.durationValue, unit: String(localized: "active", comment: "Active duration"))
        Divider().frame(height: 28).padding(.horizontal, 12)
        statChip(value: viewModel.avgSpeedValue, unit: viewModel.avgSpeedUnit)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
  }

  private func statChip(value: String, unit: String) -> some View {
    VStack(spacing: 1) {
      Text(value)
        .font(.system(size: 17, weight: .semibold))
      Text(unit)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
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
    FullScreenMapView(route: route)
  }
  .modelContainer(container)
}
