//
//  CoreLocation+ExtensionsTests.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import Testing

@MainActor
struct CoreLocationExtensionsTests {

  // MARK: - ActivityTypeSetting tests

  @Test
  func activityTypeSettingRawValuesMatchPlist() async {
    #expect(ActivityTypeSetting.automatic.rawValue == "automatic")
    #expect(ActivityTypeSetting.automotive.rawValue == "automotive")
    #expect(ActivityTypeSetting.fitness.rawValue == "fitness")
    #expect(ActivityTypeSetting.other.rawValue == "other")
    #expect(ActivityTypeSetting.flight.rawValue == "flight")
  }

  @Test
  func activityTypeSettingMapsToCorrectCLActivityType() async {
    #expect(ActivityTypeSetting.automatic.activityType == .automotiveNavigation)
    #expect(ActivityTypeSetting.automotive.activityType == .automotiveNavigation)
    #expect(ActivityTypeSetting.fitness.activityType == .fitness)
    #expect(ActivityTypeSetting.other.activityType == .other)
    #expect(ActivityTypeSetting.flight.activityType == .airborne)
  }

  @Test
  func activityTypeSettingDefaultIsAutomotive() async {
    #expect(ActivityTypeSetting.default == .automotive)
  }

  // MARK: - CLActivityType(fromSettings:) tests

  @Test
  func fromSettingsDelegatesToEnum() async {
    for setting in ActivityTypeSetting.allCases {
      #expect(CLActivityType(fromSettings: setting.rawValue) == setting.activityType)
    }
  }

  @Test
  func fromSettingsDefaultsToOtherNavigationForUnknownValue() async {
    #expect(CLActivityType(fromSettings: "unexpected-value") == .otherNavigation)
  }

}
