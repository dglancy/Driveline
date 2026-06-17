//
//  OnboardingPresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import Foundation

enum OnboardingPresenter {

  // MARK: - Welcome

  static var welcomeTitle: String {
    String(localized: "Welcome to Driveline", comment: "Onboarding welcome screen title")
  }

  static var welcomeSubtitle: String {
    String(localized: "Automatic drive tracking — connect, drive, done.", comment: "Onboarding welcome screen subtitle")
  }

  static var welcomeRow1Title: String {
    String(localized: "Records every drive automatically", comment: "Onboarding welcome feature row 1 title")
  }

  static var welcomeRow1Body: String {
    String(localized: "No buttons to remember. Driveline logs each trip from start to finish.", comment: "Onboarding welcome feature row 1 body")
  }

  static var welcomeRow2Title: String {
    String(localized: "Starts when your car connects", comment: "Onboarding welcome feature row 2 title")
  }

  static var welcomeRow2Body: String {
    String(localized: "A Shortcut fires the moment you join CarPlay or your car's Bluetooth.", comment: "Onboarding welcome feature row 2 body")
  }

  static var welcomeRow3Title: String {
    String(localized: "Private by design", comment: "Onboarding welcome feature row 3 title")
  }

  static var welcomeRow3Body: String {
    String(localized: "Your routes stay on your device. Location is used only to record drives.", comment: "Onboarding welcome feature row 3 body")
  }

  static var getStarted: String {
    String(localized: "Get Started", comment: "Onboarding welcome primary button")
  }

  // MARK: - Location (While Using)

  static var locationTitle: String {
    String(localized: "Driveline needs your location", comment: "Onboarding location primer title")
  }

  static var locationBody1: String {
    String(localized: "Driveline uses your location to record the route, distance, and duration of each drive. Without it, trips can't be tracked.", comment: "Onboarding location primer body paragraph 1")
  }

  static var allowLocationAccess: String {
    String(localized: "Allow Location Access", comment: "Onboarding location primer button — not yet granted")
  }

  static var locationGrantedLabel: String {
    String(localized: "Location access granted", comment: "Onboarding confirmation that When In Use location access is granted")
  }

  // MARK: - Location (Always)

  static var alwaysTitle: String {
    String(localized: "Allow location \u{201C}Always\u{201D}", comment: "Onboarding Always-location primer title")
  }

  static var alwaysBody1: String {
    String(localized: "To record drives automatically — even when Driveline isn't open — your location needs to be available in the background.", comment: "Onboarding Always-location primer body paragraph 1")
  }

  static var alwaysRow1Title: String {
    String(localized: "Hands-free recording", comment: "Onboarding Always-location info row 1 title")
  }

  static var alwaysRow1Body: String {
    String(localized: "Drives capture without opening the app.", comment: "Onboarding Always-location info row 1 body")
  }

  static var alwaysRow2Title: String {
    String(localized: "Used only while driving", comment: "Onboarding Always-location info row 2 title")
  }

  static var alwaysRow2Body: String {
    String(localized: "Background location activates around your trips, not all day.", comment: "Onboarding Always-location info row 2 body")
  }

  static var enableBackgroundLocation: String {
    String(localized: "Enable Background Location", comment: "Onboarding Always-location primer button — not yet granted")
  }

  static var alwaysGrantedLabel: String {
    String(localized: "Always Allow enabled", comment: "Onboarding confirmation that Always location access is granted")
  }

  // MARK: - Shared

  static var continueAction: String {
    String(localized: "Continue", comment: "Onboarding continue button — shown after permission is granted")
  }
}
