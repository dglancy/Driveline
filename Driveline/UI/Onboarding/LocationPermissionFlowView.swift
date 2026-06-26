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
  let onDismiss: () -> Void

  // MARK: - Lifecycle

  init(initialStatus: CLAuthorizationStatus, onComplete: @escaping () -> Void, onDismiss: @escaping () -> Void) {
    _step = State(initialValue: initialStatus == .authorizedWhenInUse ? .always : .whenInUse)
    self.onComplete = onComplete
    self.onDismiss = onDismiss
  }

  // MARK: - Body

  var body: some View {
    Group {
      switch step {
      case .whenInUse:
        OnboardingLocationView(onNext: advanceToAlways, onDismiss: onDismiss)
      case .always:
        OnboardingAlwaysView(onNext: onComplete, onDismiss: onDismiss)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: step)
  }

  // MARK: - Private

  private func advanceToAlways() {
    if locationService.authorizationStatus == .authorizedAlways {
      onComplete()
    } else {
      step = .always
    }
  }
}
