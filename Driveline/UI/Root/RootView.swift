//
//  RootView.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import SwiftUI
import UIKit

struct RootView: View {

  // MARK: - Properties

  @Binding var isOnboardingPresented: Bool

  @Environment(SpotlightIndexingService.self) private var spotlightIndexingService

  // MARK: - Body

  var body: some View {
    if UIDevice.current.userInterfaceIdiom == .pad {
      DrivesSplitView()
    } else {
      HomeView()
        .fullScreenCover(isPresented: $isOnboardingPresented) {
          OnboardingWelcomeView {
            var prefs = UserPreferences()
            prefs.setHasSeenWelcome(true)
            isOnboardingPresented = false
          }
          .interactiveDismissDisabled()
        }
        .onChange(of: isOnboardingPresented, initial: true) { _, isPresented in
          RecordButtonTip.isOnboardingPresented = isPresented
          StatsPanelTip.isOnboardingPresented = isPresented
          EditDriveTip.isOnboardingPresented = isPresented
        }
    }
  }
}
