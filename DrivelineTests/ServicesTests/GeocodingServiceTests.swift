//
//  GeocodingServiceTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation
import Testing

struct GeocodingServiceTests {

  // MARK: - subLocality preferred

  @Test
  func combinesSubLocalityAndLocality() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: "Surry Hills",
        locality: "Sydney",
        cityWithContext: "Sydney, Australia",
        cityName: "Sydney",
        shortAddress: "Crown St, Surry Hills",
        name: "Crown St"
      )
    )

    #expect(result == "Surry Hills, Sydney")
  }

  @Test
  func returnsSubLocalityAloneWhenLocalityNil() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: "Camden",
        locality: nil,
        cityWithContext: nil,
        cityName: nil,
        shortAddress: nil,
        name: nil
      )
    )

    #expect(result == "Camden")
  }

  @Test
  func returnsSubLocalityAloneWhenLocalityMatches() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: "Galway",
        locality: "Galway",
        cityWithContext: "Galway, Ireland",
        cityName: "Galway",
        shortAddress: nil,
        name: nil
      )
    )

    #expect(result == "Galway")
  }

  // MARK: - Fallback chain

  @Test
  func fallsBackToCityWithContextWhenSubLocalityNil() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: nil,
        locality: "Dublin",
        cityWithContext: "Dublin, Ireland",
        cityName: "Dublin",
        shortAddress: "O'Connell St, Dublin",
        name: "O'Connell St"
      )
    )

    #expect(result == "Dublin, Ireland")
  }

  @Test
  func fallsBackToCityNameWhenCityWithContextNil() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: nil,
        locality: nil,
        cityWithContext: nil,
        cityName: "Dublin",
        shortAddress: "O'Connell St, Dublin",
        name: "O'Connell St"
      )
    )

    #expect(result == "Dublin")
  }

  @Test
  func fallsBackToShortAddressWhenNoCityInfo() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: nil,
        locality: nil,
        cityWithContext: nil,
        cityName: nil,
        shortAddress: "M50, Co. Dublin",
        name: "M50"
      )
    )

    #expect(result == "M50, Co. Dublin")
  }

  @Test
  func fallsBackToNameWhenShortAddressNil() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: nil,
        locality: nil,
        cityWithContext: nil,
        cityName: nil,
        shortAddress: nil,
        name: "Phoenix Park"
      )
    )

    #expect(result == "Phoenix Park")
  }

  @Test
  func returnsNilWhenAllFieldsNil() {
    let result = GeocodingService.composePlaceName(
      from: GeocodingService.PlaceNameComponents(
        subLocality: nil,
        locality: nil,
        cityWithContext: nil,
        cityName: nil,
        shortAddress: nil,
        name: nil
      )
    )

    #expect(result == nil)
  }
}
