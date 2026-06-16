//
//  EditDriveView.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct EditDriveView: View {

  // MARK: - Properties

  @State private var driveName: String
  @State private var startPlaceName: String
  @State private var endPlaceName: String

  @Environment(\.dismiss) private var dismiss
  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService

  private let drive: Drive

  // MARK: - Lifecycle

  init(drive: Drive) {
    self.drive = drive
    _driveName = State(initialValue: drive.name ?? "")
    _startPlaceName = State(initialValue: drive.startPlaceName ?? "")
    _endPlaceName = State(initialValue: drive.endPlaceName ?? "")
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        Section(String(localized: "Drive Name", comment: "Edit drive section header")) {
          TextField(
            String(localized: "Drive name", comment: "Drive name text field placeholder"),
            text: $driveName
          )
          .clearable($driveName)
        }

        Section(String(localized: "Start Location", comment: "Edit drive section header")) {
          TextField(
            String(localized: "Start location name", comment: "Start location text field placeholder"),
            text: $startPlaceName
          )
          .clearable($startPlaceName)
        }

        Section(String(localized: "End Location", comment: "Edit drive section header")) {
          TextField(
            String(localized: "End location name", comment: "End location text field placeholder"),
            text: $endPlaceName
          )
          .clearable($endPlaceName)
        }
      }
      .navigationTitle(String(localized: "Edit Drive", comment: "Edit drive sheet title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button.cancel { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button.save {
            DriveEditor.apply(name: driveName, startPlace: startPlaceName, endPlace: endPlaceName, to: drive)
            Task { await spotlightIndexingService.indexDrive(drive) }
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }
}
