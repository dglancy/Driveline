//
//  SpotlightIndexingServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 07/06/2026.
//

@testable import Driveline
import CoreSpotlight
import Foundation
import Testing

@MainActor
final class SpotlightIndexingServiceTests {

  // MARK: - searchableItem(for:)

  @Test
  func searchableItemHasCorrectIdentifier() {
    let drive = makeDrive()
    let item = makeService().searchableItem(for: drive)
    #expect(item.uniqueIdentifier == drive.id.uuidString)
  }

  @Test
  func searchableItemHasCorrectDomainIdentifier() {
    let drive = makeDrive()
    let item = makeService().searchableItem(for: drive)
    #expect(item.domainIdentifier == SpotlightIndexingService.domainIdentifier)
  }

  @Test
  func searchableItemTitleIsDisplayName() {
    let drive = makeDrive(name: "My Road Trip")
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.title == "My Road Trip")
  }

  @Test
  func searchableItemKeywordsContainsBothPlaceNames() {
    let drive = makeDrive(startPlaceName: "Home", endPlaceName: "Work")
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.keywords == ["Home", "Work"])
  }

  @Test
  func searchableItemKeywordsContainsOnlyStartPlaceWhenEndIsNil() {
    let drive = makeDrive(startPlaceName: "Home")
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.keywords == ["Home"])
  }

  @Test
  func searchableItemKeywordsIsNilWhenNeitherPlaceNameSet() {
    let drive = makeDrive()
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.keywords == nil)
  }

  @Test
  func searchableItemContentDescriptionShowsBothPlaceNames() {
    let drive = makeDrive(startPlaceName: "Home", endPlaceName: "Work")
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.contentDescription == "Home → Work")
  }

  @Test
  func searchableItemContentDescriptionShowsOnlyStartWhenEndIsNil() {
    let drive = makeDrive(startPlaceName: "Home")
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.contentDescription == "Home")
  }

  @Test
  func searchableItemContentDescriptionIsNilWhenNoPlaceNames() {
    let drive = makeDrive()
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.contentDescription == nil)
  }

  @Test
  func searchableItemStartDateMatchesDrive() {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let drive = makeDrive(startedAt: date)
    let item = makeService().searchableItem(for: drive)
    #expect(item.attributeSet.startDate == date)
  }

  // MARK: - indexDrive

  @Test
  func indexDriveIndexesTheDrive() async {
    let mockIndex = MockSpotlightIndex()
    let drive = makeDrive(startPlaceName: "Home", endPlaceName: "Work")

    await makeService(index: mockIndex).indexDrive(drive)

    #expect(mockIndex.indexedItems.count == 1)
    #expect(mockIndex.indexedItems[0].uniqueIdentifier == drive.id.uuidString)
  }

  // MARK: - deindexDrives

  @Test
  func deindexDrivesRemovesIdentifiers() async {
    let mockIndex = MockSpotlightIndex()
    let id1 = UUID()
    let id2 = UUID()

    await makeService(index: mockIndex).deindexDrives([id1, id2])

    #expect(mockIndex.deletedIdentifiers == [id1.uuidString, id2.uuidString])
  }

  @Test
  func deindexDrivesWithEmptyArrayDoesNothing() async {
    let mockIndex = MockSpotlightIndex()

    await makeService(index: mockIndex).deindexDrives([])

    #expect(mockIndex.deletedIdentifiers.isEmpty)
  }

  // MARK: - Helpers

  private func makeService(index: any SpotlightIndexProtocol = MockSpotlightIndex()) -> SpotlightIndexingService {
    SpotlightIndexingService(index: index)
  }

  private func makeDrive(
    name: String? = nil,
    startedAt: Date = .now,
    startPlaceName: String? = nil,
    endPlaceName: String? = nil
  ) -> Drive {
    let drive = Drive(name: name, trigger: .manual)
    drive.status = .finished
    drive.startedAt = startedAt
    drive.endedAt = .now
    drive.startPlaceName = startPlaceName
    drive.endPlaceName = endPlaceName
    return drive
  }
}

// MARK: - MockSpotlightIndex

@MainActor
final class MockSpotlightIndex: SpotlightIndexProtocol {

  // MARK: - Properties

  private(set) var indexedItems: [CSSearchableItem] = []
  private(set) var deletedIdentifiers: [String] = []

  // MARK: - SpotlightIndexProtocol

  func indexSearchableItems(_ items: [CSSearchableItem]) async throws {
    indexedItems.append(contentsOf: items)
  }

  func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws {
    deletedIdentifiers.append(contentsOf: identifiers)
  }
}
