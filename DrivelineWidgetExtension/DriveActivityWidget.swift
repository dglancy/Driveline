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
        Image(systemName: "car.fill")
          .foregroundStyle(.red)
      } compactTrailing: {
        DriveActivityCompactTrailingView(context: context)
      } minimal: {
        Image(systemName: "car.fill")
          .foregroundStyle(.red)
      }
    }
  }
}

// MARK: - Lock Screen / Banner

private struct DriveActivityLockScreenView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      headerRow
      if let placeName = context.state.startPlaceName {
        Text(String(localized: "From: \(placeName)", comment: "Live Activity start location label"))
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Divider()
      statsRow
      finishButton
    }
    .padding()
  }

  private var headerRow: some View {
    HStack(spacing: 8) {
      Image(systemName: "car.fill")
        .foregroundStyle(.red)
      Text(String(localized: "Recording Drive", comment: "Live Activity title"))
        .font(.headline.weight(.semibold))
      Spacer()
      RecordingPulsingDot()
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
        .background(.red)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
  }
}

// MARK: - Dynamic Island Compact Trailing

private struct DriveActivityCompactTrailingView: View {

  let context: ActivityViewContext<DriveActivityAttributes>

  var body: some View {
    Text("\(formattedSpeed(context.state.avgSpeedMetresPerSecond)) \(speedUnitSymbol())")
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
        Image(systemName: "timer")
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
          .background(.red)
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
      HStack(alignment: .lastTextBaseline, spacing: 3) {
        Text(value)
          .font(.title3.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(.primary)
        Text(label)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Text(sublabel)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

private struct LiveActivityTimerColumn: View {

  let startedAt: Date

  var body: some View {
    VStack(spacing: 2) {
      Text(startedAt, style: .timer)
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(.primary)
      Text(String(localized: "Duration", comment: "Live Activity duration label"))
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

private struct RecordingPulsingDot: View {

  @State private var pulsing = false

  var body: some View {
    Circle()
      .fill(.red)
      .frame(width: 8, height: 8)
      .opacity(pulsing ? 0.3 : 1.0)
      .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
      .onAppear { pulsing = true }
  }
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
