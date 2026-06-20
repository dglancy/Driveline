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

  // MARK: - Automations Intro

  static var automationsIntroTitle: String {
    String(localized: "Two quick automations", comment: "Onboarding automations intro screen title")
  }

  static var automationsIntroBody: String {
    String(localized: "For truly hands-free recording, set up two automations in the Shortcuts app. They start and stop Driveline the moment your iPhone connects to your car — over CarPlay or Bluetooth.", comment: "Onboarding automations intro screen body")
  }

  static var automationsIntroRow1Title: String {
    String(localized: "When your car connects", comment: "Onboarding automations intro row 1 title")
  }

  static var automationsIntroRow1Body: String {
    String(localized: "Driveline starts recording your drive.", comment: "Onboarding automations intro row 1 body")
  }

  static var automationsIntroRow2Title: String {
    String(localized: "When your car disconnects", comment: "Onboarding automations intro row 2 title")
  }

  static var automationsIntroRow2Body: String {
    String(localized: "Driveline stops and saves your drive.", comment: "Onboarding automations intro row 2 body")
  }

  static var setUpAutomations: String {
    String(localized: "Set Up Automations", comment: "Onboarding automations intro primary button")
  }

  // MARK: - Automation Detail (Start)

  static var automationStartTitle: String {
    String(localized: "Set up “Start Drive”", comment: "Onboarding automation start screen title")
  }

  static var automationStartBody: String {
    String(localized: "This automation starts recording the moment CarPlay connects — or your car's Bluetooth pairs.", comment: "Onboarding automation start screen body")
  }

  static var automationStartStep1: String {
    String(localized: "Open the **Shortcuts** app", comment: "Onboarding automation start step 1")
  }

  static var automationStartStep2: String {
    String(localized: "Tap **Automation** at the bottom", comment: "Onboarding automation start step 2")
  }

  static var automationStartStep3: String {
    String(localized: "Tap **+** then **New Automation**", comment: "Onboarding automation start step 3")
  }

  static var automationStartStep4: String {
    String(localized: "Choose **CarPlay** → **Connects** (or **Bluetooth** → your car)", comment: "Onboarding automation start step 4")
  }

  static var automationStartStep5: String {
    String(localized: "Tap **Add Action**, search **Start Drive** and select it", comment: "Onboarding automation start step 5")
  }

  static var automationStartStep6: String {
    String(localized: "Turn off **Ask Before Running**", comment: "Onboarding automation start step 6")
  }

  static var automationStartStep7: String {
    String(localized: "Tap **Done**", comment: "Onboarding automation start step 7")
  }

  // MARK: - Automation Detail (Finish)

  static var automationFinishTitle: String {
    String(localized: "Set up “Finish Drive”", comment: "Onboarding automation finish screen title")
  }

  static var automationFinishBody: String {
    String(localized: "This automation stops and saves your drive the moment CarPlay disconnects — or your car's Bluetooth drops.", comment: "Onboarding automation finish screen body")
  }

  static var automationFinishStep1: String {
    String(localized: "Open the **Shortcuts** app", comment: "Onboarding automation finish step 1")
  }

  static var automationFinishStep2: String {
    String(localized: "Tap **Automation** at the bottom", comment: "Onboarding automation finish step 2")
  }

  static var automationFinishStep3: String {
    String(localized: "Tap **+** then **New Automation**", comment: "Onboarding automation finish step 3")
  }

  static var automationFinishStep4: String {
    String(localized: "Choose **CarPlay** → **Disconnects** (or **Bluetooth** → your car)", comment: "Onboarding automation finish step 4")
  }

  static var automationFinishStep5: String {
    String(localized: "Tap **Add Action**, search **Finish Drive** and select it", comment: "Onboarding automation finish step 5")
  }

  static var automationFinishStep6: String {
    String(localized: "Turn off **Ask Before Running**", comment: "Onboarding automation finish step 6")
  }

  static var automationFinishStep7: String {
    String(localized: "Tap **Done**", comment: "Onboarding automation finish step 7")
  }

  // MARK: - Shared Automation

  static var openShortcuts: String {
    String(localized: "Open Shortcuts", comment: "Onboarding button to open the Shortcuts app")
  }

  static var startUsingDriveline: String {
    String(localized: "Start Using Driveline", comment: "Onboarding final completion button")
  }

  // MARK: - Shared

  static var continueAction: String {
    String(localized: "Continue", comment: "Onboarding continue button — shown after permission is granted")
  }

  static var doneAction: String {
    String(localized: "Done", comment: "Final button on automation setup flow")
  }

  static var openSettingsAction: String {
    String(localized: "Open Settings", comment: "Button shown when location permission is denied — opens iOS Settings")
  }

  static var locationDeniedBody: String {
    String(localized: "Location access was denied. Open Settings to enable it.", comment: "Explanation shown on location permission screen when access is denied")
  }

  static var alwaysDeniedBody: String {
    String(localized: "Location access was denied. Open Settings and choose Always to enable background recording.", comment: "Explanation shown on the Always location screen when access is denied")
  }
}
