//
//  OnboardingWelcomeView.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import SwiftUI

struct OnboardingWelcomeView: View {
  
  // MARK: - Properties
  
  let onNext: () -> Void
  
  // MARK: - Body
  
  var body: some View {
    VStack(spacing: 0) {
      Spacer()
      heroSection
      Spacer(minLength: 36)
      featureRows
      Spacer()
      footer
    }
    .padding(.horizontal, 28)
    .padding(.bottom, 40)
  }
  
  // MARK: - Private Views
  
  private var appIcon: some View {
    Group {
      if let name = Bundle.main.iconFileName, let ui = UIImage(named: name) {
        Image(uiImage: ui)
          .resizable()
          .frame(width: 92, height: 92)
          .clipShape(RoundedRectangle(cornerRadius: 21))
          .shadow(color: .accentColor.opacity(0.4), radius: 15, y: 8)
          .accessibilityHidden(true)
      } else {
        Color.clear.frame(width: 92, height: 92)
      }
    }
  }
  
  private var heroSection: some View {
    VStack(spacing: 20) {
      appIcon
      VStack(spacing: 8) {
        Text(OnboardingPresenter.welcomeTitle)
          .font(.system(size: 32, weight: .bold))
          .multilineTextAlignment(.center)
          .tracking(-0.6)
        Text(OnboardingPresenter.welcomeSubtitle)
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
  }
  
  private var featureRows: some View {
    VStack(alignment: .leading, spacing: 24) {
      OnboardingInfoRow(
        symbol: "car.fill",
        title: OnboardingPresenter.welcomeRow1Title,
        detail: OnboardingPresenter.welcomeRow1Body
      )
      OnboardingInfoRow(
        symbol: "point.3.filled.connected.trianglepath.dotted",
        title: OnboardingPresenter.welcomeRow2Title,
        detail: OnboardingPresenter.welcomeRow2Body
      )
      OnboardingInfoRow(
        symbol: "lock.fill",
        title: OnboardingPresenter.welcomeRow3Title,
        detail: OnboardingPresenter.welcomeRow3Body
      )
    }
  }
  
  private var footer: some View {
    OnboardingPrimaryButton(title: OnboardingPresenter.getStarted, action: onNext)
  }
}
  
// MARK: - Preview

#Preview {
  return OnboardingWelcomeView(onNext: {})
}

struct AppIconView: View {
  var body: some View {
    if let name = Bundle.main.iconFileName, let ui = UIImage(named: name) {
      Image(uiImage: ui)
        .resizable()
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 21))
        .shadow(color: .accentColor.opacity(0.4), radius: 15, y: 8)
        .accessibilityHidden(true)
    }
  }
}
