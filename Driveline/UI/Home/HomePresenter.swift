//
//  HomePresenter.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import Foundation

enum StatsScope {
  case last30Days, allTime
}

enum HomePresenter {

  // MARK: - Labels

  static func statsScopeLabel(_ scope: StatsScope) -> String {
    scope == .last30Days
      ? String(localized: "last 30 days", comment: "Stats scope label for recent period")
      : String(localized: "all time", comment: "Stats scope label for all drives")
  }

  static func selectionCountText(_ count: Int) -> String {
    if count == 0 {
      return String(localized: "Select 2 drives to merge", comment: "Multiselect placeholder when nothing is selected")
    }
    return String(localized: "\(count) selected", comment: "Multiselect count of selected drives")
  }

  static func deleteConfirmationMessage(_ count: Int) -> String {
    String(
      localized: "\(count) drives and all their data will be permanently deleted.",
      comment: "Confirmation message for deleting selected drives."
    )
  }

  static var newDriveButtonTitle: String {
    String(localized: "Record Your First Drive", comment: "Button on empty state to start a new drive")
  }

  static var automationSetupTitle: String {
    String(localized: "Set Up Automated Recording", comment: "Title of the automation setup panel on the home screen")
  }

  static var automationSetupSubtitle: String {
    String(localized: "Record drives hands-free when Bluetooth or CarPlay connects.", comment: "Subtitle of the automation setup panel on the home screen")
  }
}
