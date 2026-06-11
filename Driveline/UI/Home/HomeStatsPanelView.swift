//
//  HomeStatsPanelView.swift
//  Driveline
//
//  Created by Damien Glancy on 08/06/2026.
//

import SwiftUI

struct HomeStatsPanelView: View {

  // MARK: - Properties

  let driveCount: Int
  let distanceValue: String
  let distanceUnit: String
  let scopeLabel: String
  let onTap: () -> Void

  // MARK: - Constants

  private static let scopeToggleHint = String(localized: "Double tap to switch between last 30 days and all time", comment: "Accessibility hint for toggling stats panel scope")

  // MARK: - Body

  var body: some View {
    HStack(spacing: 11) {
      StatCard(
        icon: Icons.Panels.drives,
        label: String(localized: "DRIVES", comment: "Stats panel drives card label"),
        value: "\(driveCount)",
        unit: nil,
        scopeLabel: scopeLabel
      )
      .accessibilityLabel(
        String(localized: "\(driveCount) drives, \(scopeLabel)", comment: "Accessibility label for drives stats card")
      )
      .accessibilityAddTraits(.isButton)
      .accessibilityHint(Self.scopeToggleHint)
      .accessibilityAction { onTap() }

      StatCard(
        icon: Icons.Panels.distance,
        label: String(localized: "DISTANCE", comment: "Stats panel distance card label"),
        value: distanceValue,
        unit: distanceUnit,
        scopeLabel: scopeLabel
      )
      .accessibilityLabel(
        String(localized: "\(distanceValue) \(distanceUnit), \(scopeLabel)", comment: "Accessibility label for distance stats card")
      )
      .accessibilityAddTraits(.isButton)
      .accessibilityHint(Self.scopeToggleHint)
      .accessibilityAction { onTap() }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .contentShape(Rectangle())
    .onTapGesture { onTap() }
  }
}

// MARK: - StatCard

private struct StatCard: View {

  let icon: String
  let label: String
  let value: String
  let unit: String?
  let scopeLabel: String

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Circle()
        .fill(
          RadialGradient(
            colors: [.white.opacity(0.18), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 60
          )
        )
        .frame(width: 120, height: 120)
        .offset(x: 30, y: -30)

      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 4) {
          Image(systemName: icon)
            .font(.caption2)
            .dynamicTypeSize(.xSmall ... .accessibility1)
          Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .tracking(0.5)
            .dynamicTypeSize(.xSmall ... .accessibility1)
        }
        .foregroundStyle(.white.opacity(0.8))

        Spacer()

        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(value)
            .font(.largeTitle)
            .bold()
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .dynamicTypeSize(.xSmall ... .accessibility1)
          if let unit {
            Text(unit)
              .font(.title3.weight(.semibold))
              .foregroundStyle(.white.opacity(0.8))
              .dynamicTypeSize(.xSmall ... .accessibility1)
          }
        }

        Text(scopeLabel)
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.7))
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 110)
    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
    .clipped()
  }
}

// MARK: - Preview

#Preview {
  List {
    Section {
      HomeStatsPanelView(driveCount: 6, distanceValue: "10,000", distanceUnit: "km", scopeLabel: "last 30 days", onTap: {})
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
  }
}
