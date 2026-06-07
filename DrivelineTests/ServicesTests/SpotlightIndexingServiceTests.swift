//
//  SpotlightIndexingServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 07/06/2026.
//

@testable import Driveline
import CoreSpotlight
import Foundation
import SwiftData
import Testing

@MainActor
final class SpotlightIndexingServiceTests: SwiftDataBaseTestCase {

  // MARK: - searchableItem(for:)

  @Test
  func searchableItemHasCorrectIdentifier() throws {
    let drive = try insertFinishedDrive()
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.uniqueIdentifier == drive.id.uuidString)
  }

  @Test
  func searchableItemHasCorrectDomainIdentifier() throws {
    let drive = try insertFinishedDrive()
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.domainIdentifier == SpotlightIndexingService.domainIdentifier)
  }

  @Test
  func searchableItemTitleIsDisplayName() throws {
    let drive = try insertFinishedDrive(name: "My Road Trip")
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.title == "My Road Trip")
  }

  @Test
  func searchableItemKeywordsContainsBothPlaceNames() throws {
    let drive = try insertFinishedDrive(startPlaceName: "Home", endPlaceName: "Work")
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.keywords == ["Home", "Work"])
  }

  @Test
  func searchableItemKeywordsContainsOnlyStartPlaceWhenEndIsNil() throws {
    let drive = try insertFinishedDrive(startPlaceName: "Home")
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.keywords == ["Home"])
  }

  @Test
  func searchableItemKeywordsIsNilWhenNeitherPlaceNameSet() throws {
    let drive = try insertFinishedDrive()
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.keywords == nil)
  }

  @Test
  func searchableItemContentDescriptionShowsBothPlaceNames() throws {
    let drive = try insertFinishedDrive(startPlaceName: "Home", endPlaceName: "Work")
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.contentDescription == "Home → Work")
  }

  @Test
  func searchableItemContentDescriptionShowsOnlyStartWhenEndIsNil() throws {
    let drive = try insertFinishedDrive(startPlaceName: "Home")
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.contentDescription == "Home")
  }

  @Test
  func searchableItemContentDescriptionIsNilWhenNoPlaceNames() throws {
    let drive = try insertFinishedDrive()
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.contentDescription == nil)
  }

  @Test
  func searchableItemStartDateMatchesDrive() throws {
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let drive = try insertFinishedDrive(startedAt: date)
    let service = makeService()

    let item = service.searchableItem(for: drive)

    #expect(item.attributeSet.startDate == date)
  }

  // MARK: - reindexAll

  @Test
  func reindexAllIndexesFinishedDrives() async throws {
    let mockIndex = MockSpotlightIndex()
    let service = makeService(index: mockIndex)
    try insertFinishedDrive()

    await service.reindexAll()

    #expect(mockIndex.indexedItems.count == 1)
  }

  @Test
  func reindexAllSkipsRecordingDrives() async throws {
    let mockIndex = MockSpotlightIndex()
    let service = makeService(index: mockIndex)
    let drive = Drive(trigger: .manual)
    drive.status = .recording
    context!.insert(drive)
    try context!.save()

    await service.reindexAll()

    #expect(mockIndex.indexedItems.isEmpty)
  }

  @Test
  func reindexAllDeletesBeforeReindexing() async throws {
    let mockIndex = MockSpotlightIndex()
    let service = makeService(index: mockIndex)
    try insertFinishedDrive()

    await service.reindexAll()

    #expect(mockIndex.deletedDomainIdentifiers == [SpotlightIndexingService.domainIdentifier])
  }

  @Test
  func reindexAllDoesNotIndexWhenNoFinishedDrives() async throws {
    let mockIndex = MockSpotlightIndex()
    let service = makeService(index: mockIndex)

    await service.reindexAll()

    #expect(mockIndex.indexedItems.isEmpty)
  }

  @Test
  func reindexAllIndexesMultipleFinishedDrives() async throws {
    let mockIndex = MockSpotlightIndex()
    let service = makeService(index: mockIndex)
    try insertFinishedDrive()
    try insertFinishedDrive()

    await service.reindexAll()

    #expect(mockIndex.indexedItems.count == 2)
  }

  // MARK: - Helpers

  private func makeService(index: any SpotlightIndexProtocol = MockSpotlightIndex()) -> SpotlightIndexingService {
    SpotlightIndexingService(modelContext: context!, index: index)
  }

  @discardableResult
  private func insertFinishedDrive(
    name: String? = nil,
    startedAt: Date = .now,
    startPlaceName: String? = nil,
    endPlaceName: String? = nil
  ) throws -> Drive {
    let drive = Drive(name: name, trigger: .manual)
    drive.status = .finished
    drive.startedAt = startedAt
    drive.endedAt = .now
    drive.startPlaceName = startPlaceName
    drive.endPlaceName = endPlaceName
    context!.insert(drive)
    try context!.save()
    return drive
  }
}

// MARK: - MockSpotlightIndex

@MainActor
final class MockSpotlightIndex: SpotlightIndexProtocol {

  // MARK: - Properties

  private(set) var indexedItems: [CSSearchableItem] = []
  private(set) var deletedDomainIdentifiers: [String] = []

  // MARK: - SpotlightIndexProtocol

  func indexSearchableItems(_ items: [CSSearchableItem]) async throws {
    indexedItems.append(contentsOf: items)
  }

  func deleteSearchableItems(withDomainIdentifiers identifiers: [String]) async throws {
    deletedDomainIdentifiers.append(contentsOf: identifiers)
  }
}
