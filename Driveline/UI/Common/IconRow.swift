//
//  IconRow.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

struct IconRow<LeadingIcon: View>: View {

  // MARK: - Properties

  private let leadingIcon: LeadingIcon
  let title: String
  let subtitle: String?
  let trailing: String?

  // MARK: - Lifecycle

  init(
    title: String,
    subtitle: String? = nil,
    trailing: String? = nil,
    @ViewBuilder leadingIcon: () -> LeadingIcon
  ) {
    self.title = title
    self.subtitle = subtitle
    self.trailing = trailing
    self.leadingIcon = leadingIcon()
  }

  // MARK: - Body

  var body: some View {
    HStack(spacing: 12) {
      leadingIcon
        .frame(width: 24)

      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.callout)
          .dynamicTypeSize(.xSmall ... .large)
        if let subtitle {
          Text(subtitle)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .dynamicTypeSize(.xSmall ... .large)
        }
      }
      
      Spacer()
      
      if let trailing {
        Text(trailing)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}
