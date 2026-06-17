//
//  OnboardingPresenterTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

@testable import Driveline
import Testing

@Suite("OnboardingPresenter")
@MainActor
struct OnboardingPresenterTests {

  @Test func welcomeTitleIsNonEmpty() {
    #expect(!OnboardingPresenter.welcomeTitle.isEmpty)
  }

  @Test func welcomeSubtitleIsNonEmpty() {
    #expect(!OnboardingPresenter.welcomeSubtitle.isEmpty)
  }

  @Test func welcomeFeatureRowsAreNonEmpty() {
    #expect(!OnboardingPresenter.welcomeRow1Title.isEmpty)
    #expect(!OnboardingPresenter.welcomeRow1Body.isEmpty)
    #expect(!OnboardingPresenter.welcomeRow2Title.isEmpty)
    #expect(!OnboardingPresenter.welcomeRow2Body.isEmpty)
    #expect(!OnboardingPresenter.welcomeRow3Title.isEmpty)
    #expect(!OnboardingPresenter.welcomeRow3Body.isEmpty)
  }

  @Test func getStartedIsNonEmpty() {
    #expect(!OnboardingPresenter.getStarted.isEmpty)
  }

  @Test func locationStringsAreNonEmpty() {
    #expect(!OnboardingPresenter.locationTitle.isEmpty)
    #expect(!OnboardingPresenter.locationBody1.isEmpty)
    #expect(!OnboardingPresenter.allowLocationAccess.isEmpty)
    #expect(!OnboardingPresenter.locationGrantedLabel.isEmpty)
  }

  @Test func alwaysStringsAreNonEmpty() {
    #expect(!OnboardingPresenter.alwaysTitle.isEmpty)
    #expect(!OnboardingPresenter.alwaysBody1.isEmpty)
    #expect(!OnboardingPresenter.alwaysRow1Title.isEmpty)
    #expect(!OnboardingPresenter.alwaysRow1Body.isEmpty)
    #expect(!OnboardingPresenter.alwaysRow2Title.isEmpty)
    #expect(!OnboardingPresenter.alwaysRow2Body.isEmpty)
    #expect(!OnboardingPresenter.enableBackgroundLocation.isEmpty)
    #expect(!OnboardingPresenter.alwaysGrantedLabel.isEmpty)
  }

  @Test func continueActionIsNonEmpty() {
    #expect(!OnboardingPresenter.continueAction.isEmpty)
  }

  @Test func alwaysTitleContainsCurlyQuotes() {
    #expect(OnboardingPresenter.alwaysTitle.contains("\u{201C}"))
    #expect(OnboardingPresenter.alwaysTitle.contains("\u{201D}"))
  }
}
