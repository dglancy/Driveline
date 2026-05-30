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

  @EnvironmentObject private var routeService: RouteService
  @Environment(\.dismiss) private var dismiss

  // MARK: - Body

  var body: some View {
    ZStack {
      Color(.systemBackground).ignoresSafeArea()
      TimelineView(.periodic(from: .now, by: 1.0)) { _ in
        mainContent
      }
    }
  }

  // MARK: - Private Views

  private var mainContent: some View {
    VStack(spacing: 0) {
      header
      Spacer()
      heroSection
      Spacer()
      batteryNote
      triggerLine
      controlButtons
    }
  }

  private var header: some View {
    HStack {
      Button { dismiss() } label: {
        ZStack {
          Circle().fill(Color(.systemFill))
          Image(systemName: "chevron.down")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)

      Spacer()
      recordingBadge
      Spacer()

      Color.clear.frame(width: 36, height: 36)
    }
    .padding(.horizontal, 14)
    .padding(.top, 16)
  }

  private var recordingBadge: some View {
    let accentColor: Color = routeService.isPaused ? .orange : .red

    return HStack(spacing: 8) {
      if routeService.isPaused {
        RoundedRectangle(cornerRadius: 2)
          .fill(accentColor)
          .frame(width: 9, height: 9)
      } else {
        PulsingDot(color: accentColor)
      }
      Text(routeService.isPaused ? "PAUSED" : "RECORDING")
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(accentColor)
        .tracking(1.4)
    }
    .padding(.vertical, 7)
    .padding(.horizontal, 14)
    .background(Color(.secondarySystemBackground))
    .clipShape(Capsule())
  }

  private var heroSection: some View {
    let route = routeService.route
    let elapsedSeconds = Int(route?.activeDurationSeconds ?? 0)
    let accentColor: Color = routeService.isPaused ? .orange : .red

    return VStack(spacing: 0) {
      Text("Elapsed")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color(.secondaryLabel))
        .tracking(1)
        .textCase(.uppercase)
        .padding(.bottom, 6)

      Text(TimeInterval(elapsedSeconds).elapsedTimeString())
        .font(.system(size: 74, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(Color(.label))
        .opacity(routeService.isPaused ? 0.5 : 1)
        .animation(.easeInOut(duration: 0.3), value: routeService.isPaused)

      HStack(alignment: .lastTextBaseline, spacing: 6) {
        let distanceMetres = route?.distanceMetres ?? 0.0
        Text(distanceMetres.localizedDistanceValueString())
          .font(.system(size: 52, weight: .semibold))
          .monospacedDigit()
          .foregroundStyle(accentColor)
        Text(distanceMetres.localizedDistanceUnitSymbol())
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(Color(.secondaryLabel))
      }
      .padding(.top, 22)

      secondaryStats(route: route)
        .padding(.top, 30)
    }
  }

  private func secondaryStats(route: Route?) -> some View {
    let speedValue = routeService.isPaused ? "—" : routeService.currentSpeedMs?.localizedSpeedValueString() ?? "—"
    let speedUnit = (routeService.currentSpeedMs ?? 0).localizedSpeedUnitSymbol()

    return HStack(spacing: 0) {
      StatColumn(value: speedValue, label: speedUnit)
      Divider().frame(height: 36)
      StatColumn(value: route.map { "\($0.positions.count)" } ?? "0", label: "logged")
      Divider().frame(height: 36)
      StatColumn(value: route?.startedAt.formatted(date: .omitted, time: .shortened) ?? "—", label: "Started")
    }
    .frame(width: 280)
  }

  private var batteryNote: some View {
    HStack(spacing: 11) {
      Image(systemName: "battery.75percent")
        .font(.system(size: 22))
        .foregroundStyle(Color(.secondaryLabel))
      Text("Running in the background to save battery. Your full route map appears here when the drive ends.")
        .font(.system(size: 13.5))
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

  private var triggerLine: some View {
    let trigger = routeService.route?.trigger
    let iconName = trigger == .bluetooth ? "bluetooth" : "hand.tap"

    return HStack(spacing: 6) {
      Image(systemName: iconName)
        .font(.system(size: 14))
        .foregroundStyle(Color(.tertiaryLabel))
      Text(trigger?.rawValue ?? "")
        .font(.system(size: 13))
        .foregroundStyle(Color(.tertiaryLabel))
    }
    .padding(.bottom, 16)
  }

  private var controlButtons: some View {
    HStack(spacing: 60) {
      VStack(spacing: 9) {
        Button {
          if routeService.isPaused {
            routeService.resumeRoute()
          } else {
            routeService.pauseRoute()
          }
        } label: {
          ZStack {
            Circle()
              .fill(Color(.systemFill))
              .overlay(Circle().stroke(Color(.separator), lineWidth: 2))
            Image(systemName: routeService.isPaused ? "play.fill" : "pause.fill")
              .font(.system(size: 28))
              .foregroundStyle(Color(.label))
          }
          .frame(width: 76, height: 76)
        }
        .buttonStyle(.plain)

        Text(routeService.isPaused ? "Resume" : "Pause")
          .font(.system(size: 13))
          .foregroundStyle(Color(.secondaryLabel))
      }

      VStack(spacing: 9) {
        Button {
          routeService.endRoute()
        } label: {
          ZStack {
            Circle()
              .fill(.red)
              .shadow(color: .red.opacity(0.35), radius: 10, y: 6)
            Image(systemName: "stop.fill")
              .font(.system(size: 28))
              .foregroundStyle(.white)
          }
          .frame(width: 76, height: 76)
        }
        .buttonStyle(.plain)

        Text("End Drive")
          .font(.system(size: 13))
          .foregroundStyle(Color(.secondaryLabel))
      }
    }
    .padding(.bottom, 42)
  }

}

// MARK: - Subviews

private struct PulsingDot: View {

  // MARK: - Properties

  let color: Color
  @State private var animating = false

  // MARK: - Body

  var body: some View {
    ZStack {
      Circle()
        .fill(color)
        .scaleEffect(animating ? 2.2 : 1.0)
        .opacity(animating ? 0 : 0.5)
      Circle()
        .fill(color)
    }
    .frame(width: 9, height: 9)
    .onAppear {
      withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) {
        animating = true
      }
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
        .font(.system(size: 21, weight: .semibold))
        .monospacedDigit()
        .foregroundStyle(Color(.label))
      Text(label)
        .font(.system(size: 12))
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
  let route = Route(name: "Morning Drive")
  let routeService = RouteService(
    modelContext: container.mainContext,
    locationService: locationService,
    locationDataRecorder: locationDataRecorder,
    initialRoute: route
  )
  RecordingView()
    .environmentObject(routeService)
    .modelContainer(container)
}
