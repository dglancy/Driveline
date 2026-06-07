//
//  SpotlightIndexingService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreSpotlight
import Foundation
import SwiftData

// MARK: - Protocol

@MainActor
protocol SpotlightIndexProtocol: AnyObject {
  func indexSearchableItems(_ items: [CSSearchableItem]) async throws
  func deleteSearchableItems(withDomainIdentifiers identifiers: [String]) async throws
}

extension CSSearchableIndex: SpotlightIndexProtocol {}

// MARK: - SpotlightIndexingService

@MainActor
final class SpotlightIndexingService {

  // MARK: - Properties

  static let domainIdentifier = Constants.App.bundleIdentifier

  @ObservationIgnored private let modelContext: ModelContext
  @ObservationIgnored private let index: any SpotlightIndexProtocol

  // MARK: - Lifecycle

  init(modelContext: ModelContext, index: any SpotlightIndexProtocol = CSSearchableIndex.default()) {
    self.modelContext = modelContext
    self.index = index
  }

  // MARK: - Actions

  func reindexAll() async {
    try? await index.deleteSearchableItems(withDomainIdentifiers: [Self.domainIdentifier])
    let drives = fetchFinishedDrives()
    guard !drives.isEmpty else { return }
    let items = drives.map { searchableItem(for: $0) }
    try? await index.indexSearchableItems(items)
  }

  // MARK: - Internal

  func searchableItem(for drive: Drive) -> CSSearchableItem {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
    attributeSet.title = drive.displayName
    let keywords = [drive.startPlaceName, drive.endPlaceName].compactMap { $0 }
    attributeSet.keywords = keywords.isEmpty ? nil : keywords
    attributeSet.contentDescription = contentDescription(for: drive)
    attributeSet.startDate = drive.startedAt
    attributeSet.endDate = drive.endedAt
    return CSSearchableItem(
      uniqueIdentifier: drive.id.uuidString,
      domainIdentifier: Self.domainIdentifier,
      attributeSet: attributeSet
    )
  }

  // MARK: - Private

  private func fetchFinishedDrives() -> [Drive] {
    let descriptor = FetchDescriptor<Drive>()
    return ((try? modelContext.fetch(descriptor)) ?? []).filter { $0.status == .finished }
  }

  private func contentDescription(for drive: Drive) -> String? {
    switch (drive.startPlaceName, drive.endPlaceName) {
    case (let start?, let end?): return "\(start) → \(end)"
    case (let start?, nil): return start
    case (nil, let end?): return end
    case (nil, nil): return nil
    }
  }
}
