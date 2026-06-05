//
//  GlassButton.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct GlassButton: View {

  // MARK: - Properties

  let systemImage: String
  let accessibilityLabel: LocalizedStringResource
  let action: () -> Void

  // MARK: - Body

  var body: some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.callout.weight(.semibold))
        .foregroundStyle(.primary)
        .frame(width: 44, height: 44)
        .background(.regularMaterial, in: Circle())
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .dynamicTypeSize(.xSmall ... .accessibility1)
    }
    .accessibilityLabel(Text(accessibilityLabel))
  }
}
