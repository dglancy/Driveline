//
//  DriveManagementStateTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 27/06/2026.
//

@testable import Driveline
import Foundation
import Testing

@Suite("DriveManagementState")
@MainActor
struct DriveManagementStateTests {

  // MARK: - enterSelectMode

  @Test
  func enterSelectModeSetsIsSelectMode() {
    let state = DriveManagementState()
    state.enterSelectMode()
    #expect(state.isSelectMode == true)
  }

  @Test
  func enterSelectModeClearsSelectedIDs() {
    let state = DriveManagementState()
    state.selectedDriveIDs.insert(UUID())
    state.enterSelectMode()
    #expect(state.selectedDriveIDs.isEmpty)
  }

  // MARK: - exitSelectMode

  @Test
  func exitSelectModeClearsIsSelectMode() {
    let state = DriveManagementState()
    state.enterSelectMode()
    state.exitSelectMode()
    #expect(state.isSelectMode == false)
  }

  @Test
  func exitSelectModeClearsSelectedIDs() {
    let state = DriveManagementState()
    let id = UUID()
    state.selectedDriveIDs.insert(id)
    state.exitSelectMode()
    #expect(state.selectedDriveIDs.isEmpty)
  }

  // MARK: - toggleSelection

  @Test
  func toggleSelectionAddsID() {
    let state = DriveManagementState()
    let id = UUID()
    state.toggleSelection(for: id)
    #expect(state.selectedDriveIDs.contains(id))
  }

  @Test
  func toggleSelectionRemovesAlreadySelectedID() {
    let state = DriveManagementState()
    let id = UUID()
    state.toggleSelection(for: id)
    state.toggleSelection(for: id)
    #expect(!state.selectedDriveIDs.contains(id))
  }

  // MARK: - canMerge / canDelete

  @Test
  func canMergeRequiresExactlyTwoSelected() {
    let state = DriveManagementState()
    #expect(!state.canMerge)
    state.toggleSelection(for: UUID())
    #expect(!state.canMerge)
    state.toggleSelection(for: UUID())
    #expect(state.canMerge)
    state.toggleSelection(for: UUID())
    #expect(!state.canMerge)
  }

  @Test
  func canDeleteRequiresAtLeastOneSelected() {
    let state = DriveManagementState()
    #expect(!state.canDelete)
    state.toggleSelection(for: UUID())
    #expect(state.canDelete)
  }

  // MARK: - selectedDrives

  @Test
  func selectedDrivesReturnsOnlySelectedDrives() {
    let state = DriveManagementState()
    let drive1 = makeDrive()
    let drive2 = makeDrive()
    let drive3 = makeDrive()
    let sections = [DriveSection(title: "Today", rows: [DriveRow(drive: drive1), DriveRow(drive: drive2), DriveRow(drive: drive3)])]

    state.toggleSelection(for: drive1.id)
    state.toggleSelection(for: drive3.id)

    let selected = state.selectedDrives(from: sections)
    #expect(selected.count == 2)
    #expect(selected.contains { $0.id == drive1.id })
    #expect(selected.contains { $0.id == drive3.id })
  }

  @Test
  func selectedDrivesReturnsEmptyWhenNoneSelected() {
    let state = DriveManagementState()
    let sections = [DriveSection(title: "Today", rows: [DriveRow(drive: makeDrive())])]
    #expect(state.selectedDrives(from: sections).isEmpty)
  }

  // MARK: - triggerMerge

  @Test
  func triggerMergeSortsDrivesChronologically() {
    let state = DriveManagementState()
    let older = makeDrive(startedAt: Date(timeIntervalSinceReferenceDate: 1000))
    let newer = makeDrive(startedAt: Date(timeIntervalSinceReferenceDate: 2000))
    let sections = [DriveSection(title: "Today", rows: [DriveRow(drive: newer), DriveRow(drive: older)])]

    state.toggleSelection(for: older.id)
    state.toggleSelection(for: newer.id)
    state.triggerMerge(from: sections)

    #expect(state.drivesToMerge.count == 2)
    #expect(state.drivesToMerge[0].id == older.id)
    #expect(state.drivesToMerge[1].id == newer.id)
  }

  @Test
  func triggerMergeSetsShowingMergeSheet() {
    let state = DriveManagementState()
    let drive1 = makeDrive(startedAt: Date(timeIntervalSinceReferenceDate: 1000))
    let drive2 = makeDrive(startedAt: Date(timeIntervalSinceReferenceDate: 2000))
    let sections = [DriveSection(title: "Today", rows: [DriveRow(drive: drive1), DriveRow(drive: drive2)])]

    state.toggleSelection(for: drive1.id)
    state.toggleSelection(for: drive2.id)
    state.triggerMerge(from: sections)

    #expect(state.showingMergeSheet == true)
  }
}

// MARK: - Helpers

private func makeDrive(startedAt: Date = .now) -> Drive {
  let drive = Drive()
  drive.startedAt = startedAt
  return drive
}
