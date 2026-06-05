//
//  EditDriveView.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct EditDriveView: View {

  // MARK: - Properties

  @State private var viewModel: EditDriveViewModel
  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(drive: Drive) {
    _viewModel = State(initialValue: EditDriveViewModel(drive: drive))
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        Section(String(localized: "Drive Name", comment: "Edit drive section header")) {
          TextField(
            String(localized: "Drive name", comment: "Drive name text field placeholder"),
            text: $viewModel.driveName
          )
        }

        Section(String(localized: "Start Location", comment: "Edit drive section header")) {
          TextField(
            String(localized: "Start location name", comment: "Start location text field placeholder"),
            text: $viewModel.startPlaceName
          )
        }

        Section(String(localized: "End Location", comment: "Edit drive section header")) {
          TextField(
            String(localized: "End location name", comment: "End location text field placeholder"),
            text: $viewModel.endPlaceName
          )
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
            viewModel.save()
            dismiss()
          }
          .disabled(viewModel.isSaveDisabled)
          .fontWeight(.semibold)
        }
      }
    }
  }
}
