//
//  MoreMenuActionSheet.swift
//  AutoRoute
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

struct MoreMenuActionSheet: View {

  // MARK: - Properties

  @Bindable var viewModel: RouteDetailViewModel

  // MARK: - Body

  var body: some View {
    VStack(spacing: 8) {
      VStack(spacing: 0) {
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            viewModel.showingMoreMenu = false
          }
          viewModel.showingEditRoute = true
        } label: {
          Text(String(localized: "Edit Route Details", comment: "More menu action"))
            .font(.title3)
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
            .font(.title3)
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
          .font(.title3.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 18)
      }
      .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
  }
}
