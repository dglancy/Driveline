//
//  OnboardingAutomationsIntroView.swift
//  Driveline
//
//  Created by Damien Glancy on 18/06/2026.
//

import SwiftUI

struct OnboardingAutomationsIntroView: View {

  // MARK: - Properties

  let onNext: () -> Void

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          heroIcon
          textContent
          infoRows
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
        .shadow(color: .accentColor.opacity(0.36), radius: 15, y: 8)
      Image(systemName: "gearshape.2.fill")
        .font(.system(size: 42, weight: .medium))
        .foregroundStyle(.white)
        .accessibilityHidden(true)
    }
  }

  private var textContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(OnboardingPresenter.automationsIntroTitle)
        .font(.system(size: 28, weight: .bold))
        .tracking(-0.5)
        .fixedSize(horizontal: false, vertical: true)
      Text(OnboardingPresenter.automationsIntroBody)
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var infoRows: some View {
    VStack(alignment: .leading, spacing: 18) {
      OnboardingInfoRow(
        symbol: "point.3.filled.connected.trianglepath.dotted",
        title: OnboardingPresenter.automationsIntroRow1Title,
        detail: OnboardingPresenter.automationsIntroRow1Body
      )
      OnboardingInfoRow(
        symbol: "bolt.slash.fill",
        title: OnboardingPresenter.automationsIntroRow2Title,
        detail: OnboardingPresenter.automationsIntroRow2Body
      )
    }
  }

  private var footer: some View {
    OnboardingPrimaryButton(title: OnboardingPresenter.setUpAutomations, action: onNext)
  }
}
