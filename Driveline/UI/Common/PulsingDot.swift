//
//  PulsingDot.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct PulsingDot: View {

  // MARK: - Properties

  let color: Color
  let size: CGFloat
  @State private var animating = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  // MARK: - Lifecycle

  init(color: Color = .red, size: CGFloat = 10) {
    self.color = color
    self.size = size
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      Circle()
        .fill(color)
        .scaleEffect(animating ? 2.0 : 1.0)
        .opacity(animating ? 0 : 0.4)
      Circle()
        .fill(color)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
        animating = true
      }
    }
    .onChange(of: reduceMotion) { _, newValue in
      if newValue {
        animating = false
      } else {
        withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
          animating = true
        }
      }
    }
  }
}
