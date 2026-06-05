//
//  SelectionToolbar.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

struct SelectionToolbar: View {

  // MARK: - Properties

  let canMerge: Bool
  let canDelete: Bool
  let selectionCountText: String
  let onMerge: () -> Void
  let onDelete: () -> Void

  // MARK: - Body

  var body: some View {
    HStack {
      Button(action: onMerge) {
        Label(
          String(localized: "Merge", comment: "Merge selected drives button"),
          systemImage: Icons.merge
        )
        .font(.body.weight(.medium))
      }
      .disabled(!canMerge)
      .frame(maxWidth: .infinity, alignment: .leading)

      Text(selectionCountText)
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)

      Button(String(localized: "Delete", comment: "Delete selected drives button"), action: onDelete)
        .font(.body.weight(.medium))
        .foregroundStyle(canDelete ? Color.red : Color(.tertiaryLabel))
        .disabled(!canDelete)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding(.horizontal, 18)
    .padding(.top, 10)
    .padding(.bottom, 30)
    .background(.regularMaterial)
    .overlay(alignment: .top) {
      Divider()
    }
  }
}
