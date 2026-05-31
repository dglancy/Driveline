//
//  ExportRoutePNGTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import AutoRoute
import Foundation
import Testing

@Suite("ExportRoutePNG")
@MainActor
final class ExportRoutePNGTests: SwiftDataBaseTestCase {

  // MARK: - Error descriptions

  @Test
  func snapshotFailureErrorIncludesMessage() {
    let error = ExportRoutePNGError.snapshotFailure("Connection timeout")
    #expect(error.errorDescription?.contains("Connection timeout") == true)
  }

  @Test
  func dataPreparationFailureHasUserFacingDescription() {
    let error = ExportRoutePNGError.dataPreparationFailure
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription?.isEmpty == false)
  }

  @Test
  func fileWriteFailureErrorIncludesMessage() {
    let error = ExportRoutePNGError.fileWriteFailure("Disk full")
    #expect(error.errorDescription?.contains("Disk full") == true)
  }

  // MARK: - MapSize dimensions

  @Test
  func lowSizeIsCorrect() {
    #expect(MapSize.low.size == CGSize(width: 800, height: 600))
  }

  @Test
  func mediumSizeIsCorrect() {
    #expect(MapSize.medium.size == CGSize(width: 1024, height: 768))
  }

  @Test
  func high1SizeIsCorrect() {
    #expect(MapSize.high1.size == CGSize(width: 1600, height: 1200))
  }

  @Test
  func high2SizeIsCorrect() {
    #expect(MapSize.high2.size == CGSize(width: 1920, height: 1080))
  }

  @Test
  func highestSizeIsCorrect() {
    #expect(MapSize.highest.size == CGSize(width: 2400, height: 1800))
  }

  // MARK: - MapSize initialiser

  @Test
  func mapSizeInitialisesFromValidLowercaseString() {
    #expect(MapSize(from: "low") == .low)
    #expect(MapSize(from: "medium") == .medium)
    #expect(MapSize(from: "high1") == .high1)
    #expect(MapSize(from: "high2") == .high2)
    #expect(MapSize(from: "highest") == .highest)
  }

  @Test
  func mapSizeInitialisesFromMixedCaseString() {
    #expect(MapSize(from: "LOW") == .low)
    #expect(MapSize(from: "High2") == .high2)
    #expect(MapSize(from: "HIGHEST") == .highest)
  }

  @Test
  func mapSizeInitialisesFromStringWithSurroundingWhitespace() {
    #expect(MapSize(from: "  low  ") == .low)
    #expect(MapSize(from: "\thigh2\n") == .high2)
  }

  @Test
  func mapSizeReturnsNilForInvalidString() {
    #expect(MapSize(from: "ultra") == nil)
    #expect(MapSize(from: "") == nil)
  }

  @Test
  func mapSizeSizeForStringReturnsMatchingSize() {
    #expect(MapSize.size(for: "low") == MapSize.low.size)
    #expect(MapSize.size(for: "highest") == MapSize.highest.size)
  }

  @Test
  func mapSizeSizeForStringReturnsDefaultSizeForInvalidKey() {
    #expect(MapSize.size(for: "invalid") == MapSize.high2.size)
  }

  @Test
  func mapSizeSizeForStringUsesSuppliedDefaultForInvalidKey() {
    #expect(MapSize.size(for: "invalid", default: .low) == MapSize.low.size)
  }

  // MARK: - RouteWidth values

  @Test
  func routeWidthValuesAreCorrect() {
    #expect(RouteWidth.thin.width == 2.0)
    #expect(RouteWidth.medium.width == 6.0)
    #expect(RouteWidth.thick.width == 10.0)
  }

  // MARK: - RouteWidth initialiser

  @Test
  func routeWidthInitialisesFromValidLowercaseString() {
    #expect(RouteWidth(from: "thin") == .thin)
    #expect(RouteWidth(from: "medium") == .medium)
    #expect(RouteWidth(from: "thick") == .thick)
  }

  @Test
  func routeWidthInitialisesFromMixedCaseString() {
    #expect(RouteWidth(from: "THIN") == .thin)
    #expect(RouteWidth(from: "Medium") == .medium)
    #expect(RouteWidth(from: "THICK") == .thick)
  }

  @Test
  func routeWidthInitialisesFromStringWithSurroundingWhitespace() {
    #expect(RouteWidth(from: "  thin  ") == .thin)
  }

  @Test
  func routeWidthReturnsNilForInvalidString() {
    #expect(RouteWidth(from: "ultrawide") == nil)
    #expect(RouteWidth(from: "") == nil)
  }

  // MARK: - Empty route

  @Test
  func throwsEmptyRouteErrorWhenRouteHasNoPositions() async {
    let route = Route(name: "Empty Route")

    await #expect(throws: ExportRouteError.emptyRoute) {
      _ = try await ExportRoutePNG().export(route: route)
    }
  }
}
