//
//  MergeRoutesView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct MergeRoutesView: View {

  // MARK: - Properties

  @State private var viewModel: MergeRoutesViewModel
  let onConfirm: ([Route], String) -> Void
  let onCancel: () -> Void

  // MARK: - Lifecycle

  init(routes: [Route], onConfirm: @escaping ([Route], String) -> Void, onCancel: @escaping () -> Void) {
    _viewModel = State(initialValue: MergeRoutesViewModel(routes: routes))
    self.onConfirm = onConfirm
    self.onCancel = onCancel
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          orderSection
          nameSection
          combinedResultSection
          disclaimerText
        }
        .padding(.bottom, 20)
      }
      Divider()
      confirmButton
    }
    .background(Color(.systemGroupedBackground))
  }

  // MARK: - Private Views

  private var header: some View {
    ZStack {
      Text("Merge Routes")
        .font(.system(size: 17, weight: .semibold))
      HStack {
        Button(String(localized: "Cancel", comment: "Dismiss merge sheet")) {
          onCancel()
        }
        .font(.system(size: 17))
        Spacer()
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(Color(.systemGroupedBackground))
  }

  private var orderSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      sectionHeader(String(localized: "Order", comment: "Merge order section header"))
      ZStack(alignment: .trailing) {
        VStack(spacing: 8) {
          MiniRouteCard(route: viewModel.first, index: 1)
          MiniRouteCard(route: viewModel.second, index: 2)
        }
        swapButton
          .padding(.trailing, 14)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 22)
  }

  private var swapButton: some View {
    Button {
      withAnimation(.easeInOut(duration: 0.2)) {
        viewModel.swapOrder()
      }
    } label: {
      Image(systemName: "arrow.up.arrow.down")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.tint)
        .frame(width: 36, height: 36)
        .background(Color(.systemGroupedBackground))
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
    .buttonStyle(.plain)
  }

  private var nameSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      sectionHeader(String(localized: "Merged Route Name", comment: "Merge name section header"))
      TextField(
        String(localized: "Route name", comment: "Merge name text field placeholder"),
        text: $viewModel.mergedName
      )
      .font(.system(size: 17))
      .padding(.horizontal, 15)
      .padding(.vertical, 13)
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding(.horizontal, 16)
    .padding(.top, 22)
  }

  private var combinedResultSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      sectionHeader(String(localized: "Combined Result", comment: "Merge combined result section header"))
      HStack(spacing: 0) {
        statColumn(
          value: viewModel.formattedTotalDistance,
          label: String(localized: "Total distance", comment: "Merge stat: total combined distance")
        )
        Divider().frame(height: 38)
        statColumn(
          value: viewModel.formattedTotalDuration,
          label: String(localized: "Total duration", comment: "Merge stat: total combined duration")
        )
        Divider().frame(height: 38)
        statColumn(
          value: viewModel.totalPositionCount.formatted(),
          label: String(localized: "Track points", comment: "Merge stat: combined GPS track point count")
        )
      }
      .padding(16)
      .background(Color(.secondarySystemGroupedBackground))
      .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .padding(.horizontal, 16)
    .padding(.top, 22)
  }

  private var disclaimerText: some View {
    Text(
      "The two GPS tracks are joined end-to-end in this order. The original routes are removed and can't be restored.",
      comment: "Merge disclaimer about track joining and deletion"
    )
    .font(.system(size: 13))
    .foregroundStyle(.secondary)
    .padding(.horizontal, 22)
    .padding(.top, 12)
  }

  private var confirmButton: some View {
    Button {
      onConfirm(viewModel.orderedRoutes, viewModel.mergedName)
    } label: {
      Label(
        String(localized: "Merge into One Route", comment: "Merge confirmation button"),
        systemImage: "arrow.triangle.merge"
      )
      .font(.system(size: 17, weight: .semibold))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 15)
      .background(.tint)
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    .buttonStyle(.plain)
    .padding(.horizontal, 16)
    .padding(.top, 12)
    .padding(.bottom, 30)
    .background(Color(.systemGroupedBackground))
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.system(size: 13))
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
      .tracking(0.2)
      .padding(.bottom, 8)
  }

  private func statColumn(value: String, label: String) -> some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(.tint)
      Text(label)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Subviews

private struct MiniRouteCard: View {

  // MARK: - Properties

  let route: Route
  let index: Int

  // MARK: - Body

  var body: some View {
    HStack(spacing: 13) {
      ZStack {
        Circle()
          .fill(.tint)
          .frame(width: 26, height: 26)
        Text("\(index)")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.white)
      }
      VStack(alignment: .leading, spacing: 1) {
        Text(route.name)
          .font(.system(size: 16, weight: .semibold))
          .lineLimit(1)
        Text(dateTimeLabel)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .trailing, spacing: 1) {
        Text(route.distanceMetres.localizedDistanceString())
          .font(.system(size: 15, weight: .medium))
        Text(route.activeDurationSeconds.localizedDurationString())
          .font(.system(size: 12))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 13)
    .background(Color(.secondarySystemGroupedBackground))
    .clipShape(RoundedRectangle(cornerRadius: 14))
  }

  private var dateTimeLabel: String {
    let datePart = route.startedAt.formatted(.dateTime.month(.abbreviated).day())
    let timePart = route.startedAt.formatted(.dateTime.hour().minute())
    let parts: [String?] = ["\(datePart) · \(timePart)", route.startPlaceName]
    return parts.compactMap { $0 }.joined(separator: " · ")
  }
}
