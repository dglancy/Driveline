//
//  AutomationSetupFlowView.swift
//  Driveline
//
//  Created by Damien Glancy on 20/06/2026.
//

import SwiftUI

struct AutomationSetupFlowView: View {

  // MARK: - Types

  private enum Step { case intro, start, finish }

  // MARK: - Properties

  @State private var step: Step = .intro
  let onComplete: () -> Void
  let onCancel: () -> Void

  // MARK: - Body

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Group {
        switch step {
        case .intro:
          OnboardingAutomationsIntroView { step = .start }
        case .start:
          OnboardingAutomationDetailView(kind: .start) { step = .finish }
        case .finish:
          OnboardingAutomationDetailView(kind: .finish, finishTitle: OnboardingPresenter.doneAction, onNext: onComplete)
        }
      }
      .animation(.easeInOut(duration: 0.3), value: step)

      Button(action: onCancel) {
        Image(systemName: "xmark.circle.fill")
          .font(.title2)
          .foregroundStyle(.secondary, .quaternary)
      }
      .padding()
      .accessibilityLabel(String(localized: "Close", comment: "Close button to dismiss the automation setup flow"))
    }
  }
}
