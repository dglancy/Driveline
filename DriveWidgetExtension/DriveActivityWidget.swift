//
//  DriveActivityWidget.swift
//  DrivelineWidgetExtension
//
//  Created by Damien Glancy on 06/06/2026.
//

import ActivityKit
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
        Image(systemName: Icons.car)
          .foregroundStyle(Color.brand)
      } compactTrailing: {
        DriveActivityCompactTrailingView(context: context)
      } minimal: {
        Image(systemName: Icons.car)
          .foregroundStyle(Color.brand)
      }
    }
  }
}

// MARK: - Lock Screen / Banner

private struct DriveActivityLockScreenView: View {

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
      Image(systemName: Icons.car)
        .foregroundStyle(Color.brand)
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
    Link(destination: URL(string: "driveline://finish")!) {
      Text(String(localized: "Finish Drive", comment: "Live Activity finish drive button"))
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(Color.brand)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }
}

// MARK: - Dynamic Island Compact Trailing

private struct DriveActivityCompactTrailingView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    Text("\(formattedDistance(context.state.distanceMetres)) \(distanceUnitSymbol())")
      .font(.caption2.weight(.semibold))
      .monospacedDigit()
      .foregroundStyle(.primary)
  }
}

// MARK: - Dynamic Island Expanded Regions

private struct DriveActivityExpandedLeadingView: View {

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

private struct DriveActivityExpandedTrailingView: View {

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

private struct DriveActivityExpandedBottomView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    HStack {
      HStack(spacing: 6) {
        Image(systemName: Icons.timer)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(context.attributes.startedAt, style: .timer)
          .font(.subheadline.weight(.medium))
          .monospacedDigit()
          .foregroundStyle(.primary)
      }
      Spacer()
      Link(destination: URL(string: "driveline://finish")!) {
        Text(String(localized: "Finish Drive", comment: "Live Activity expanded finish drive button"))
          .font(.caption.weight(.semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.brand)
          .clipShape(Capsule())
      }
    }
    .padding(.horizontal, 4)
    .padding(.bottom, 6)
  }
}

// MARK: - Shared Subviews

private struct LiveActivityStatColumn: View {

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

private struct LiveActivityTimerColumn: View {

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

private func formattedDistance(_ metres: Double) -> String {
  let unit: UnitLength = Locale.current.measurementSystem == .metric ? .kilometers : .miles
  let value = Measurement(value: metres, unit: UnitLength.meters).converted(to: unit).value
  let formatter = NumberFormatter()
  formatter.maximumFractionDigits = 1
  formatter.minimumFractionDigits = 1
  return formatter.string(from: NSNumber(value: value)) ?? "0.0"
}

private func distanceUnitSymbol() -> String {
  Locale.current.measurementSystem == .metric ? UnitLength.kilometers.symbol : UnitLength.miles.symbol
}

private func formattedSpeed(_ metresPerSecond: Double) -> String {
  let unit: UnitSpeed = Locale.current.measurementSystem == .metric ? .kilometersPerHour : .milesPerHour
  let value = Measurement(value: metresPerSecond, unit: UnitSpeed.metersPerSecond).converted(to: unit).value
  return Int(value.rounded()).formatted()
}

private func speedUnitSymbol() -> String {
  Locale.current.measurementSystem == .metric ? UnitSpeed.kilometersPerHour.symbol : UnitSpeed.milesPerHour.symbol
}
