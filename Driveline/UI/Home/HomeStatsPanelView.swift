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

  // MARK: - Body

  var body: some View {
    HStack(spacing: 11) {
      StatCard(
        icon: "checkmark.circle",
        label: String(localized: "DRIVES", comment: "Stats panel drives card label"),
        value: "\(driveCount)",
        unit: nil
      )
      .accessibilityLabel(
        String(localized: "\(driveCount) drives in the last 30 days", comment: "Accessibility label for drives stats card")
      )

      StatCard(
        icon: "arrow.right",
        label: String(localized: "DISTANCE", comment: "Stats panel distance card label"),
        value: distanceValue,
        unit: distanceUnit
      )
      .accessibilityLabel(
        String(localized: "\(distanceValue) \(distanceUnit) in the last 30 days", comment: "Accessibility label for distance stats card")
      )
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}

// MARK: - StatCard

private struct StatCard: View {

  let icon: String
  let label: String
  let value: String
  let unit: String?

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
          Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .tracking(0.5)
        }
        .foregroundStyle(.white.opacity(0.8))

        Spacer()

        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(value)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
          if let unit {
            Text(unit)
              .font(.title3.weight(.semibold))
              .foregroundStyle(.white.opacity(0.8))
          }
        }

        Text(String(localized: "last 30 days", comment: "Stats card scope caption"))
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.7))
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
      HomeStatsPanelView(driveCount: 6, distanceValue: "93.5", distanceUnit: "km")
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
  }
}
