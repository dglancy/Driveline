//
//  DriveListContent.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import SwiftData
import SwiftUI
import TipKit

enum DriveListMode {
  case pushNavigation
  case selectionDriven(selectedID: Binding<UUID?>)
}

struct DriveListContent: View {

  // MARK: - Properties

  let sections: [DriveSection]
  @Bindable var managementState: DriveManagementState
  let mode: DriveListMode
  let recentDriveCount: Int
  let activeStatsPresenter: HomeStatsPresenter
  let statsScopeLabel: String
  let isSearchActive: Bool
  let onStatsToggle: () -> Void
  var showAutomationBanner: Bool = false
  var onShowAutomation: (() -> Void)?

  @Environment(\.modelContext) private var modelContext
  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService

  // MARK: - Body

  var body: some View {
    List {
      if recentDriveCount > 0 && !managementState.isSelectMode && !isSearchActive {
        Section {
          HomeStatsPanelView(
            driveCount: activeStatsPresenter.driveCount,
            distanceValue: activeStatsPresenter.distanceValue,
            distanceUnit: activeStatsPresenter.distanceUnit,
            scopeLabel: statsScopeLabel,
            onTap: onStatsToggle
          )
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
          .popoverTip(StatsPanelTip())
        }
        .listSectionSpacing(8)
      }

      if showAutomationBanner && !managementState.isSelectMode && !isSearchActive {
        Section {
          HomeAutomationSetupPanelView { onShowAutomation?() }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listSectionSpacing(8)
      }

      ForEach(sections) { section in
        Section(section.title) {
          ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
            if managementState.isSelectMode {
              Button {
                managementState.toggleSelection(for: row.drive.id)
              } label: {
                DriveRowView(
                  drive: row.drive,
                  display: row.display,
                  style: .list(isSelected: managementState.selectedDriveIDs.contains(row.drive.id))
                )
              }
              .buttonStyle(.plain)
            } else {
              driveRow(for: row, index: index)
            }
          }
          .onDelete(perform: managementState.isSelectMode ? nil : { indexSet in
            let drives = indexSet.map { section.rows[$0].drive }
            DriveDeletion.delete(drives, in: modelContext, deindexing: spotlightIndexingService)
          })
        }
      }

      if managementState.isSelectMode {
        Color.clear
          .frame(height: 70)
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      }
    }
    .contentMargins(.top, 0, for: .scrollContent)
  }

  // MARK: - Private

  @ViewBuilder
  private func driveRow(for row: DriveRow, index: Int) -> some View {
    switch mode {
    case .pushNavigation:
      NavigationLink(value: row.drive) {
        DriveRowView(drive: row.drive, display: row.display)
      }
      .accessibilityIdentifier("Drive row \(index)")
    case .selectionDriven(let selectedID):
      Button {
        selectedID.wrappedValue = row.drive.id
      } label: {
        DriveRowView(drive: row.drive, display: row.display)
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("Drive row \(index)")
    }
  }
}
