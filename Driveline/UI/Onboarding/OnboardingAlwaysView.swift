//
//  OnboardingAlwaysView.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import CoreLocation
import SwiftUI

struct OnboardingAlwaysView: View {

  // MARK: - Properties

  @Environment(LocationService.self) private var locationService
  let onNext: () -> Void

  // MARK: - Computed Properties

  private var isGranted: Bool {
    locationService.authorizationStatus == .authorizedAlways
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          heroIcon
          textContent
          infoRows
          if isGranted {
            OnboardingGrantedPill(label: OnboardingPresenter.alwaysGrantedLabel)
              .transition(.opacity.combined(with: .move(edge: .top)))
          }
        }
        .padding(28)
        .animation(.easeInOut(duration: 0.3), value: isGranted)
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
      Image(systemName: "infinity")
        .font(.system(size: 44, weight: .medium))
        .foregroundStyle(.white)
        .accessibilityHidden(true)
    }
  }

  private var textContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(OnboardingPresenter.alwaysTitle)
        .font(.system(size: 28, weight: .bold))
        .tracking(-0.5)
        .fixedSize(horizontal: false, vertical: true)
      Text(OnboardingPresenter.alwaysBody1)
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      Text("On the next screen, choose **Change to Always Allow**. This is what lets a trip record start the moment you get in the car.")
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var infoRows: some View {
    VStack(alignment: .leading, spacing: 18) {
      OnboardingInfoRow(
        symbol: "checkmark",
        title: OnboardingPresenter.alwaysRow1Title,
        detail: OnboardingPresenter.alwaysRow1Body
      )
      OnboardingInfoRow(
        symbol: "mappin.and.ellipse",
        title: OnboardingPresenter.alwaysRow2Title,
        detail: OnboardingPresenter.alwaysRow2Body
      )
    }
  }

  private var footer: some View {
    OnboardingPrimaryButton(
      title: isGranted ? OnboardingPresenter.continueAction : OnboardingPresenter.enableBackgroundLocation,
      action: isGranted ? onNext : { locationService.requestAlwaysAuthorization() }
    )
  }
}
