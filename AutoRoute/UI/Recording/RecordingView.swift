//
//  RecordingView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftData
import SwiftUI

struct RecordingView: View {

  // MARK: - Properties

  @State private var viewModel: RecordingViewModel
  @Environment(\.dismiss) private var dismiss

  // MARK: - Lifecycle

  init(routeService: RouteService) {
    _viewModel = State(initialValue: RecordingViewModel(routeService: routeService))
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      Color(.systemBackground).ignoresSafeArea()
      mainContent
    }
  }

  // MARK: - Private Views

  private var mainContent: some View {
    VStack(spacing: 0) {
      header
      Spacer()
      TimelineView(.periodic(from: .now, by: 1.0)) { _ in
        heroSection
      }
      Spacer()
      batteryNote
      Spacer()
      controlButtons
    }
  }

  private var header: some View {
    HStack {
      Button { dismiss() } label: {
        ZStack {
          Circle().fill(Color(.systemFill))
          Image(systemName: SystemImage.chevronDown)
            .font(.body.weight(.semibold))
            .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(String(localized: "Minimise recording screen", comment: "Dismiss button accessibility label"))

      Spacer()
      recordingBadge
      Spacer()

      Color.clear.frame(width: 36, height: 36)
    }
    .padding(.horizontal, 14)
    .padding(.top, 16)
  }

  private var recordingBadge: some View {
    HStack(spacing: 8) {
      if viewModel.isPaused {
        RoundedRectangle(cornerRadius: 2)
          .fill(viewModel.accentColour)
          .frame(width: 9, height: 9)
      } else {
        PulsingDot(color: viewModel.accentColour, size: 9)
      }
      let statusKey: LocalizedStringKey = viewModel.isPaused ? "PAUSED" : "RECORDING"
      Text(statusKey)
        .font(.footnote.weight(.bold))
        .foregroundStyle(viewModel.accentColour)
        .tracking(1.4)
        .accessibilityLabel(
          viewModel.isPaused
            ? String(localized: "Recording paused", comment: "Status badge accessibility label")
            : String(localized: "Recording in progress", comment: "Status badge accessibility label")
        )
    }
    .padding(.vertical, 7)
    .padding(.horizontal, 14)
    .background(Color(.secondarySystemBackground))
    .clipShape(Capsule())
  }

  private var heroSection: some View {
    VStack(spacing: 0) {
      Text("Elapsed")
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color(.secondaryLabel))
        .tracking(1)
        .textCase(.uppercase)
        .padding(.bottom, 6)
        .accessibilityHidden(true)

      Text(viewModel.elapsedDisplay)
        .font(.system(size: 74, weight: .semibold, design: .default).monospacedDigit())
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .dynamicTypeSize(.large ... .accessibility3)
        .foregroundStyle(Color(.label))
        .opacity(viewModel.isPaused ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isPaused)
        .accessibilityLabel(String(localized: "Elapsed time", comment: "Timer accessibility label"))
        .accessibilityValue(viewModel.elapsedSpeechValue)

      VStack(spacing: -6) {
        Text(viewModel.distanceValue)
          .font(.largeTitle.weight(.semibold))
          .monospacedDigit()
          .foregroundStyle(viewModel.accentColour)
        Text(viewModel.distanceUnit)
          .font(.title2.weight(.medium))
          .foregroundStyle(Color(.secondaryLabel))
      }
      .padding(.top, 22)

      secondaryStats
        .padding(.top, 30)
    }
  }

  private var secondaryStats: some View {
    HStack(spacing: 0) {
      StatColumn(value: viewModel.speedValue, label: viewModel.speedUnit)
      Divider().frame(height: 36)
      StatColumn(value: viewModel.formattedPositionCount, label: String(localized: "logged", comment: "Label for the count of GPS positions logged during a drive"))
      Divider().frame(height: 36)
      StatColumn(value: viewModel.startedAt, label: String(localized: "started", comment: "Label for the time the drive started"))
    }
    .frame(width: 280)
  }

  private var batteryNote: some View {
    HStack(spacing: 11) {
      Image(systemName: SystemImage.battery)
        .font(.title2)
        .foregroundStyle(Color(.secondaryLabel))
      Text("Running in the background to save battery. Your full route map appears here when the drive ends.")
        .font(.footnote)
        .foregroundStyle(Color(.secondaryLabel))
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 13)
    .background(Color(.secondarySystemFill))
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .padding(.horizontal, 20)
    .padding(.bottom, 18)
  }

  private var controlButtons: some View {
    HStack(spacing: 60) {
      RecordingControlButton(
        iconName: viewModel.pauseResumeIconName,
        label: viewModel.pauseResumeLabel,
        background: .fill(Color(.systemFill), stroke: Color(.separator)),
        iconColor: Color(.label),
        action: viewModel.pauseOrResume
      )

      RecordingControlButton(
        iconName: SystemImage.stop,
        label: String(localized: "End Drive", comment: "End drive button label"),
        background: .red,
        iconColor: .white,
        action: viewModel.endRoute
      )
    }
    .padding(.bottom, 42)
  }

}

// MARK: - Subviews

private struct RecordingControlButton: View {

  // MARK: - Types

  enum Background {
    case fill(Color, stroke: Color)
    case red
  }

  // MARK: - Properties

  let iconName: String
  let label: String
  let background: Background
  let iconColor: Color
  let action: () -> Void

  // MARK: - Body

  var body: some View {
    VStack(spacing: 9) {
      Button(action: action) {
        ZStack {
          switch background {
          case .fill(let fillColor, let strokeColor):
            Circle()
              .fill(fillColor)
              .overlay(Circle().stroke(strokeColor, lineWidth: 2))
          case .red:
            Circle()
              .fill(Color.red)
              .shadow(color: .red.opacity(0.35), radius: 10, y: 6)
          }
          Image(systemName: iconName)
            .font(.title)
            .foregroundStyle(iconColor)
        }
        .frame(width: 76, height: 76)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(label)

      Text(label)
        .font(.footnote)
        .foregroundStyle(Color(.secondaryLabel))
        .accessibilityHidden(true)
    }
  }

}

private struct StatColumn: View {

  // MARK: - Properties

  let value: String
  let label: String

  // MARK: - Body

  var body: some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.title3.weight(.semibold))
        .monospacedDigit()
        .foregroundStyle(Color(.label))
      Text(label)
        .font(.caption)
        .foregroundStyle(Color(.secondaryLabel))
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Preview

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: Route.self, configurations: config) // swiftlint:disable:this force_try
  let locationService = LocationService()
  let locationDataRecorder = LocationDataRecorderService(locationService: locationService, modelContext: container.mainContext)
  let route = Route(name: "Morning Drive", trigger: .automatic)
  let routeService = RouteService(
    modelContext: container.mainContext,
    locationService: locationService,
    locationDataRecorder: locationDataRecorder,
    initialRoute: route
  )
  RecordingView(routeService: routeService)
    .modelContainer(container)
}
