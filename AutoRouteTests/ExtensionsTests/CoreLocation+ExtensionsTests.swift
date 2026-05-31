//
//  Untitled.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import AutoRoute
import CoreLocation
import Foundation
import Testing

struct CoreLocationExtensionsTests {

  // MARK: - Tests

  @Test
  func mapsSettingsStringsToActivityType() async {
    #expect(CLActivityType(fromSettings: "automotive") == .automotiveNavigation)
    #expect(CLActivityType(fromSettings: "fitness") == .fitness)
    #expect(CLActivityType(fromSettings: "other") == .other)
    #expect(CLActivityType(fromSettings: "flight") == .airborne)
  }

  @Test
  func defaultsToOtherNavigation() async {
    #expect(CLActivityType(fromSettings: "unexpected-value") == .otherNavigation)
  }
  
}

