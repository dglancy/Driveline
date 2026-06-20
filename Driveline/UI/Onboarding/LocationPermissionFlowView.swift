//
//  LocationPermissionFlowView.swift
//  Driveline
//
//  Created by Damien Glancy on 20/06/2026.
//

import CoreLocation
import SwiftUI

struct LocationPermissionFlowView: View {

  // MARK: - Types

  private enum Step { case whenInUse, always }

  // MARK: - Properties

  @Environment(LocationService.self) private var locationService

  @State private var step: Step
  let onComplete: () -> Void
  let onCancel: () -> Void

  // MARK: - Lifecycle

  init(initialStatus: CLAuthorizationStatus, onComplete: @escaping () -> Void, onCancel: @escaping () -> Void) {
    _step = State(initialValue: initialStatus == .authorizedWhenInUse ? .always : .whenInUse)
    self.onComplete = onComplete
    self.onCancel = onCancel
  }

  // MARK: - Body

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Group {
        switch step {
        case .whenInUse:
          OnboardingLocationView { step = .always }
        case .always:
          OnboardingAlwaysView(onNext: onComplete)
        }
      }
      .animation(.easeInOut(duration: 0.3), value: step)

      Button(action: onCancel) {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary, .quaternary)
      }
      .padding()
      .accessibilityLabel(String(localized: "Close", comment: "Close button to dismiss the location permission flow"))
    }
  }
}
