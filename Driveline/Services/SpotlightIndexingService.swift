//
//  SpotlightIndexingService.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

import CoreSpotlight
import Foundation
import Observation

// MARK: - Protocol

@MainActor
protocol SpotlightIndexProtocol: AnyObject {
  func indexSearchableItems(_ items: [CSSearchableItem]) async throws
  func deleteSearchableItems(withIdentifiers identifiers: [String]) async throws
}

extension CSSearchableIndex: SpotlightIndexProtocol {}

// MARK: - Environment Key

import SwiftUI

private struct SpotlightIndexingServiceKey: EnvironmentKey {
  static let defaultValue: SpotlightIndexingService? = nil
}

extension EnvironmentValues {
  var spotlightIndexingService: SpotlightIndexingService? {
    get { self[SpotlightIndexingServiceKey.self] }
    set { self[SpotlightIndexingServiceKey.self] = newValue }
  }
}

// MARK: - SpotlightIndexingService

@MainActor
@Observable
final class SpotlightIndexingService {

  // MARK: - Properties

  static let domainIdentifier = Constants.App.bundleIdentifier

  @ObservationIgnored private let index: any SpotlightIndexProtocol

  // MARK: - Lifecycle

  init(index: any SpotlightIndexProtocol = CSSearchableIndex.default()) {
    self.index = index
  }

  // MARK: - Actions

  func indexDrive(_ drive: Drive) async {
    try? await index.indexSearchableItems([searchableItem(for: drive)])
  }

  func deindexDrives(_ ids: [UUID]) async {
    guard !ids.isEmpty else { return }
    try? await index.deleteSearchableItems(withIdentifiers: ids.map(\.uuidString))
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

  private func contentDescription(for drive: Drive) -> String? {
    switch (drive.startPlaceName, drive.endPlaceName) {
    case (let start?, let end?): return "\(start) → \(end)"
    case (let start?, nil): return start
    case (nil, let end?): return end
    case (nil, nil): return nil
    }
  }
}
