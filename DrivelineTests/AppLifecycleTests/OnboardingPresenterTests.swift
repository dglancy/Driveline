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

  @Test func automationsIntroStringsAreNonEmpty() {
    #expect(!OnboardingPresenter.automationsIntroTitle.isEmpty)
    #expect(!OnboardingPresenter.automationsIntroBody.isEmpty)
    #expect(!OnboardingPresenter.automationsIntroRow1Title.isEmpty)
    #expect(!OnboardingPresenter.automationsIntroRow1Body.isEmpty)
    #expect(!OnboardingPresenter.automationsIntroRow2Title.isEmpty)
    #expect(!OnboardingPresenter.automationsIntroRow2Body.isEmpty)
    #expect(!OnboardingPresenter.setUpAutomations.isEmpty)
  }

  @Test func automationStartStringsAreNonEmpty() {
    #expect(!OnboardingPresenter.automationStartTitle.isEmpty)
    #expect(!OnboardingPresenter.automationStartBody.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep1.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep2.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep3.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep4.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep5.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep6.isEmpty)
    #expect(!OnboardingPresenter.automationStartStep7.isEmpty)
  }

  @Test func automationFinishStringsAreNonEmpty() {
    #expect(!OnboardingPresenter.automationFinishTitle.isEmpty)
    #expect(!OnboardingPresenter.automationFinishBody.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep1.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep2.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep3.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep4.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep5.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep6.isEmpty)
    #expect(!OnboardingPresenter.automationFinishStep7.isEmpty)
  }

  @Test func automationSharedStringsAreNonEmpty() {
    #expect(!OnboardingPresenter.openShortcuts.isEmpty)
    #expect(!OnboardingPresenter.startUsingDriveline.isEmpty)
  }

  @Test func automationTitlesContainCurlyQuotes() {
    #expect(OnboardingPresenter.automationStartTitle.contains("\u{201C}"))
    #expect(OnboardingPresenter.automationStartTitle.contains("\u{201D}"))
    #expect(OnboardingPresenter.automationFinishTitle.contains("\u{201C}"))
    #expect(OnboardingPresenter.automationFinishTitle.contains("\u{201D}"))
  }
}
