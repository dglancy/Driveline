//
//  ViewModifiers.swift
//  AutoRoute
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

extension View {
  func cardBackground(cornerRadius: CGFloat = 14) -> some View {
    background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: cornerRadius))
  }
}
