//
//  DriveActivityWidget.swift
//  DrivelineWidgetExtension
//
//  Created by Damien Glancy on 06/06/2026.
//

import ActivityKit
import AppIntents
import Foundation
import SwiftUI
import WidgetKit

// MARK: - Widget

struct DriveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: DriveActivityAttributes.self) { context in
      DriveActivityLockScreenView(context: context)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          DriveActivityExpandedLeadingView(context: context)
        }
        DynamicIslandExpandedRegion(.trailing) {
          DriveActivityExpandedTrailingView(context: context)
        }
        DynamicIslandExpandedRegion(.bottom) {
          DriveActivityExpandedBottomView(context: context)
        }
      } compactLeading: {
        Image(systemName: Icons.Widgets.car)
          .foregroundStyle(Color.green)
      } compactTrailing: {
        DriveActivityCompactTrailingView(context: context)
      } minimal: {
        Image(systemName: Icons.Widgets.car)
          .foregroundStyle(Color.green)
      }
    }
  }
}

// MARK: - Lock Screen / Banner

struct DriveActivityLockScreenView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      headerRow
      Divider()
      statsRow
      finishButton
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }

  private var headerRow: some View {
    HStack(spacing: 8) {
      Image(systemName: Icons.Widgets.car)
        .foregroundStyle(Color.green)
      Text(String(localized: "Recording Drive", comment: "Live Activity title"))
        .font(.headline.weight(.semibold))
    }
  }

  private var statsRow: some View {
    HStack(spacing: 0) {
      LiveActivityStatColumn(
        value: formattedDistance(context.state.distanceMetres),
        label: distanceUnitSymbol(),
        sublabel: String(localized: "Distance", comment: "Live Activity distance label")
      )
      Divider().frame(height: 32)
      LiveActivityTimerColumn(startedAt: context.attributes.startedAt)
      Divider().frame(height: 32)
      LiveActivityStatColumn(
        value: formattedSpeed(context.state.avgSpeedMetresPerSecond),
        label: speedUnitSymbol(),
        sublabel: String(localized: "Avg Speed", comment: "Live Activity average speed label")
      )
    }
  }

  private var finishButton: some View {
    Button(intent: FinishDriveIntent()) {
      Text(String(localized: "Finish Drive", comment: "Live Activity finish drive button"))
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Dynamic Island Compact Trailing

struct DriveActivityCompactTrailingView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    Text("\(formattedDistance(context.state.distanceMetres)) \(distanceUnitSymbol())")
      .font(.caption2.weight(.semibold))
      .monospacedDigit()
      .foregroundStyle(.primary)
  }
}

// MARK: - Dynamic Island Expanded Regions

struct DriveActivityExpandedLeadingView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(formattedDistance(context.state.distanceMetres))
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
      Text(String(localized: "Distance (\(distanceUnitSymbol()))", comment: "Live Activity expanded distance label with unit"))
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .padding(.leading, 4)
  }
}

struct DriveActivityExpandedTrailingView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(formattedSpeed(context.state.avgSpeedMetresPerSecond))
        .font(.title2.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
      Text(speedUnitSymbol())
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .padding(.trailing, 4)
  }
}

struct DriveActivityExpandedBottomView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    HStack {
      HStack(spacing: 6) {
        Image(systemName: Icons.Widgets.timer)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(context.attributes.startedAt, style: .timer)
          .font(.subheadline.weight(.medium))
          .monospacedDigit()
          .foregroundStyle(.primary)
      }
      Spacer()
      Button(intent: FinishDriveIntent()) {
        Text(String(localized: "Finish Drive", comment: "Live Activity expanded finish drive button"))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.green)
          .clipShape(Capsule())
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 4)
    .padding(.bottom, 6)
  }
}

// MARK: - Shared Subviews

struct LiveActivityStatColumn: View {

  let value: String
  let label: String
  let sublabel: String

  var body: some View {
    VStack(spacing: 2) {
      Text("\(value) \(label)")
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .center)
      Text(sublabel)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
  }
}

struct LiveActivityTimerColumn: View {

  let startedAt: Date

  var body: some View {
    VStack(spacing: 2) {
      Text(startedAt, style: .timer)
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .foregroundStyle(.primary)
        .frame(maxWidth: .infinity, alignment: .center)
      Text(String(localized: "Duration", comment: "Live Activity duration label"))
        .font(.caption2)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
  }
}

// MARK: - Brand Color

private extension Color {
  static let brand = Color(red: 60 / 255, green: 134 / 255, blue: 92 / 255)
}

// MARK: - Formatting Helpers

@MainActor
func formattedDistance(_ metres: Double) -> String {
  Measurement(value: metres, unit: UnitLength.meters).localizedDistanceValueString()
}

func distanceUnitSymbol() -> String {
  Measurement<UnitLength>.localizedDistanceUnitSymbol()
}

@MainActor
func formattedSpeed(_ metresPerSecond: Double) -> String {
  Measurement(value: metresPerSecond, unit: UnitSpeed.metersPerSecond).localizedSpeedValueString()
}

func speedUnitSymbol() -> String {
  Measurement<UnitSpeed>.localizedSpeedUnitSymbol()
}
