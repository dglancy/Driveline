//
//  HomeAutomationSetupPanelView.swift
//  Driveline
//
//  Created by Damien Glancy on 20/06/2026.
//

import SwiftUI

struct HomeAutomationSetupPanelView: View {

  // MARK: - Properties

  let onTap: () -> Void

  // MARK: - Body

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .fill(Color.accentColor.opacity(0.12))
            .frame(width: 44, height: 44)
          Image(systemName: "gearshape.2.fill")
            .font(.body.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .accessibilityHidden(true)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(HomePresenter.automationSetupTitle)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
          Text(HomePresenter.automationSetupSubtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
          .accessibilityHidden(true)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(HomePresenter.automationSetupTitle)
    .accessibilityAddTraits(.isButton)
  }
}
