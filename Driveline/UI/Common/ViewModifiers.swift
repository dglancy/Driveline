//
//  ViewModifiers.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

extension View {
  func cardBackground(cornerRadius: CGFloat = 14) -> some View {
    background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius))
  }

  func clearable(_ text: Binding<String>) -> some View {
    modifier(ClearableTextFieldModifier(text: text))
  }
}

private struct ClearableTextFieldModifier: ViewModifier {
  @Binding var text: String

  func body(content: Content) -> some View {
    content
      .overlay(alignment: .trailing) {
        if !text.isEmpty {
          Button {
            text = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
        }
      }
  }
}
