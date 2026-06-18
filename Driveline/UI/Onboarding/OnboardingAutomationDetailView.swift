//
//  OnboardingAutomationDetailView.swift
//  Driveline
//
//  Created by Damien Glancy on 18/06/2026.
//

import SwiftUI

struct OnboardingAutomationDetailView: View {

  // MARK: - Types

  enum Kind { case start, finish }

  // MARK: - Properties

  let kind: Kind
  let onNext: () -> Void

  @Environment(\.openURL) private var openURL

  // MARK: - Computed Properties

  private var isStart: Bool { kind == .start }
  private var heroSymbol: String { isStart ? "play.fill" : "stop.fill" }

  private var title: String {
    isStart ? OnboardingPresenter.automationStartTitle : OnboardingPresenter.automationFinishTitle
  }

  private var body1: String {
    isStart ? OnboardingPresenter.automationStartBody : OnboardingPresenter.automationFinishBody
  }
  
  private var steps: [String] {
    [
      OnboardingPresenter.automationStartStep1,
      OnboardingPresenter.automationStartStep2,
      OnboardingPresenter.automationStartStep3,
      OnboardingPresenter.automationStartStep4,
      OnboardingPresenter.automationStartStep5,
      OnboardingPresenter.automationStartStep6,
      OnboardingPresenter.automationStartStep7
    ]
  }
  
  private var primaryLabel: String {
    isStart ? OnboardingPresenter.continueAction : OnboardingPresenter.startUsingDriveline
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          heroIcon
          textContent
          stepsList
        }
        .padding(28)
      }
      footer
        .padding(.horizontal, 28)
        .padding(.bottom, 40)
    }
  }

  // MARK: - Private Views

  private var heroIcon: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 28)
        .fill(Color.accentColor)
        .frame(width: 96, height: 96)
        .shadow(color: Color.accentColor.opacity(0.36), radius: 15, y: 8)
      Image(systemName: heroSymbol)
        .font(.system(size: 42, weight: .medium))
        .foregroundStyle(.white)
        .accessibilityHidden(true)
    }
  }

  private var textContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(title)
        .font(.system(size: 28, weight: .bold))
        .tracking(-0.5)
        .fixedSize(horizontal: false, vertical: true)
      Text(body1)
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var stepsList: some View {
    VStack(alignment: .leading, spacing: 14) {
      ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
        OnboardingStepRow(number: index + 1, text: step)
      }
    }
  }

  private var footer: some View {
    VStack(spacing: 12) {
      Button(OnboardingPresenter.openShortcuts) {
        if let url = URL(string: "shortcuts://") {
          openURL(url)
        }
      }
      .buttonStyle(.bordered)
      .controlSize(.extraLarge)
      .clipShape(RoundedRectangle(cornerRadius: 15))
      .frame(maxWidth: .infinity)

      OnboardingPrimaryButton(title: primaryLabel, action: onNext)
    }
  }
}

// MARK: - Step Row

private struct OnboardingStepRow: View {
  let number: Int
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 14) {
      Text("\(number)")
        .font(.footnote.weight(.bold))
        .foregroundStyle(.white)
        .frame(width: 24, height: 24)
        .background(Color.accentColor, in: Circle())
        .accessibilityHidden(true)
      Text(.init(text))
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
