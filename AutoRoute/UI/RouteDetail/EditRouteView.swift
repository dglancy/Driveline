//
//  EditRouteView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct EditRouteView: View {

  // MARK: - Properties

  @State private var viewModel: EditRouteViewModel
  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(route: Route) {
    _viewModel = State(initialValue: EditRouteViewModel(route: route))
  }

  // MARK: - Body

  var body: some View {
    NavigationStack {
      Form {
        Section(String(localized: "Route Name", comment: "Edit route section header")) {
          TextField(
            String(localized: "Route name", comment: "Route name text field placeholder"),
            text: $viewModel.routeName
          )
        }

        Section(String(localized: "Start Location", comment: "Edit route section header")) {
          TextField(
            String(localized: "Start location name", comment: "Start location text field placeholder"),
            text: $viewModel.startPlaceName
          )
        }

        Section(String(localized: "End Location", comment: "Edit route section header")) {
          TextField(
            String(localized: "End location name", comment: "End location text field placeholder"),
            text: $viewModel.endPlaceName
          )
        }
      }
      .navigationTitle(String(localized: "Edit Route", comment: "Edit route sheet title"))
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
