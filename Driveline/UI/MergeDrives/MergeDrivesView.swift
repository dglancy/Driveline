//
//  MergeDrivesView.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct MergeDrivesView: View {

  // MARK: - Properties

  @Environment(\.dismiss) private var dismiss
  @State private var orderedDrives: [Drive]
  @State private var mergedName: String

  let onConfirm: ([Drive], String) -> Void

  // MARK: - Lifecycle

  init(drives: [Drive], onConfirm: @escaping ([Drive], String) -> Void) {
    _orderedDrives = State(initialValue: drives)
    _mergedName = State(initialValue: MergeDrivesPresenter.defaultMergedName(for: drives))
    self.onConfirm = onConfirm
  }

  // MARK: - Computed Properties

  private var presenter: MergeDrivesPresenter { MergeDrivesPresenter(drives: orderedDrives) }

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
      .navigationTitle(String(localized: "Merge Drives", comment: "Merge sheet navigation title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button.cancel { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "Merge", comment: "Confirm drive merge")) {
            onConfirm(orderedDrives, mergedName)
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
          DriveRowView(drive: orderedDrives[0], display: presenter.firstDisplay, style: .card(index: 1))
          DriveRowView(drive: orderedDrives[1], display: presenter.secondDisplay, style: .card(index: 2))
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
        orderedDrives = [orderedDrives[1], orderedDrives[0]]
        mergedName = MergeDrivesPresenter.defaultMergedName(for: orderedDrives)
      }
    } label: {
      Image(systemName: Icons.Drive.reorderDrives)
        .font(.callout.weight(.medium))
        .foregroundStyle(.tint)
        .frame(width: 36, height: 36)
        .background(Color(.systemGroupedBackground))
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(String(localized: "Swap order", comment: "Accessibility label for button that swaps the order of the two drives being merged"))
  }

  private var nameSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      sectionHeader(String(localized: "Merged Drive Name", comment: "Merge name section header"))
      TextField(
        String(localized: "Drive name", comment: "Merge name text field placeholder"),
        text: $mergedName
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
          value: presenter.formattedTotalDistance,
          label: String(localized: "Total distance", comment: "Merge stat: total combined distance")
        )
        Divider().frame(height: 38)
        statColumn(
          value: presenter.formattedTotalDuration,
          label: String(localized: "Total duration", comment: "Merge stat: total combined duration")
        )
        Divider().frame(height: 38)
        statColumn(
          value: presenter.formattedTotalPositionCount,
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
      "The two drives are joined end-to-end in this order. The original drives are removed and can't be restored.",
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
