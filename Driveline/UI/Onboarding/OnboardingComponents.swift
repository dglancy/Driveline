//
//  OnboardingComponents.swift
//  Driveline
//
//  Created by Damien Glancy on 20/06/2026.
//

import SwiftUI

struct OnboardingPrimaryButton: View {
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.body.weight(.semibold))
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.borderedProminent)
    .controlSize(.extraLarge)
    .clipShape(RoundedRectangle(cornerRadius: 15))
  }
}

struct OnboardingInfoRow: View {
  let symbol: String
  let title: String
  let detail: String

  var body: some View {
    HStack(alignment: .top, spacing: 15) {
      Image(systemName: symbol)
        .font(.title2)
        .foregroundStyle(.tint)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.callout.weight(.semibold))
        Text(detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct OnboardingGrantedPill: View {
  let label: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.white, .green)
        .font(.system(size: 22))
        .accessibilityHidden(true)
      Text(label)
        .font(.subheadline.weight(.semibold))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 13)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 13))
    .accessibilityLabel(label)
  }
}
