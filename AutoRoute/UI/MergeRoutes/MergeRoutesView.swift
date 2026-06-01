//
//  MergeRoutesView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct MergeRoutesView: View {

  // MARK: - Properties

  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: MergeRoutesViewModel
  let onConfirm: ([Route], String) -> Void

  // MARK: - Lifecycle

  init(routes: [Route], onConfirm: @escaping ([Route], String) -> Void) {
    _viewModel = State(initialValue: MergeRoutesViewModel(routes: routes))
    self.onConfirm = onConfirm
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          orderSection
          nameSection
          combinedResultSection
          disclaimerText
        }
        .padding(.bottom, 20)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle(String(localized: "Merge Routes", comment: "Merge sheet navigation title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button.cancel { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "Merge", comment: "Confirm route merge")) {
            onConfirm(viewModel.orderedRoutes, viewModel.mergedName)
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }

  // MARK: - Private Views

  private var orderSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      sectionHeader(String(localized: "Order", comment: "Merge order section header"))
      ZStack(alignment: .trailing) {
        VStack(spacing: 8) {
          MiniRouteCard(display: viewModel.firstDisplay, index: 1)
          MiniRouteCard(display: viewModel.secondDisplay, index: 2)
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
      Image(systemName: SystemImage.reorderRoutes)
        .font(.callout.weight(.medium))
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
      .font(.body)
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
          value: viewModel.formattedTotalPositionCount,
          label: String(localized: "Track points", comment: "Merge stat: combined GPS track point count")
        )
      }
      .padding(16)
      .cardBackground()
    }
    .padding(.horizontal, 16)
    .padding(.top, 22)
  }

  private var disclaimerText: some View {
    Text(
      "The two routes are joined end-to-end in this order. The original routes are removed and can't be restored.",
      comment: "Merge disclaimer about track joining and deletion"
    )
    .font(.footnote)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 22)
    .padding(.top, 12)
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(.footnote)
      .foregroundStyle(.secondary)
      .textCase(.uppercase)
      .tracking(0.2)
      .padding(.bottom, 8)
  }

  private func statColumn(value: String, label: String) -> some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.tint)
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Subviews

private struct MiniRouteCard: View {

  // MARK: - Properties

  let display: MergeRoutesViewModel.MiniRouteCardDisplay
  let index: Int

  // MARK: - Body

  var body: some View {
    HStack(spacing: 13) {
      ZStack {
        Circle()
          .fill(.tint)
          .frame(width: 26, height: 26)
        Text("\(index)")
          .font(.subheadline.weight(.bold))
          .foregroundStyle(.white)
      }
      VStack(alignment: .leading, spacing: 1) {
        Text(display.name)
          .font(.callout.weight(.semibold))
          .lineLimit(1)
        Text(display.dateTimeLabel)
          .font(.footnote)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .trailing, spacing: 1) {
        Text(display.formattedDistance)
          .font(.callout.weight(.medium))
        Text(display.formattedDuration)
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 13)
    .cardBackground()
  }
}
