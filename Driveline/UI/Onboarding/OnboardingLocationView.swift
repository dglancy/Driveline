//
//  OnboardingLocationView.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import CoreLocation
import SwiftUI

struct OnboardingLocationView: View {

  // MARK: - Properties

  @Environment(LocationService.self) private var locationService
  let onNext: () -> Void

  // MARK: - Computed Properties

  private var isGranted: Bool {
    locationService.authorizationStatus == .authorizedWhenInUse
    || locationService.authorizationStatus == .authorizedAlways
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          heroIcon
          textContent
          if isGranted {
            OnboardingGrantedPill(label: OnboardingPresenter.locationGrantedLabel)
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
      Image(systemName: "mappin.and.ellipse")
        .font(.system(size: 48))
        .foregroundStyle(.white)
        .accessibilityHidden(true)
    }
  }

  private var textContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(OnboardingPresenter.locationTitle)
        .font(.system(size: 28, weight: .bold))
        .tracking(-0.5)
        .fixedSize(horizontal: false, vertical: true)
      Text(OnboardingPresenter.locationBody1)
        .font(.body)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      locationBody2
    }
  }

  private var locationBody2: some View {
    Text("On the next screen, choose **Allow While Using App** to continue.")
      .font(.body)
      .foregroundStyle(.secondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var footer: some View {
    OnboardingPrimaryButton(
      title: isGranted ? OnboardingPresenter.continueAction : OnboardingPresenter.allowLocationAccess,
      action: isGranted ? onNext : { locationService.requestWhenInUseAuthorization() }
    )
  }
}
