//
//  DriveMergeServiceTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 06/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class DriveMergeServiceTests: SwiftDataBaseTestCase {

  // MARK: - merge name

  @Test
  func mergeCreatesNewDriveWithCorrectName() throws {
    let (first, second) = makeDrivePair()
    makeService().merge(orderedDrives: [first, second], mergedName: "Long Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.name == "Long Trip")
  }

  // MARK: - merge dates

  @Test
  func mergeUsesFirstDriveStartedAt() throws {
    let start = Date(timeIntervalSinceReferenceDate: 1000)
    let (first, second) = makeDrivePair(firstStartedAt: start)
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.startedAt == start)
  }

  @Test
  func mergeUsesSecondDriveEndedAt() throws {
    let end = Date(timeIntervalSinceReferenceDate: 5000)
    let (first, second) = makeDrivePair(secondEndedAt: end)
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endedAt == end)
  }

  @Test
  func mergeFallsBackToFirstEndedAtWhenSecondEndedAtIsNil() throws {
    let end = Date(timeIntervalSinceReferenceDate: 3000)
    let (first, second) = makeDrivePair(firstEndedAt: end, secondEndedAt: nil)
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endedAt == end)
  }

  // MARK: - merge status

  @Test
  func mergeSetsStatusToFinished() throws {
    let (first, second) = makeDrivePair()
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.status == .finished)
  }

  // MARK: - merge place names

  @Test
  func mergeUsesFirstDriveStartPlaceName() throws {
    let (first, second) = makeDrivePair()
    first.startPlaceName = "Home"
    second.startPlaceName = "Café"
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.startPlaceName == "Home")
  }

  @Test
  func mergeUsesSecondDriveEndPlaceName() throws {
    let (first, second) = makeDrivePair()
    first.endPlaceName = "Midpoint"
    second.endPlaceName = "Office"
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endPlaceName == "Office")
  }

  // MARK: - merge positions

  @Test
  func mergeConcatenatesPositionsFromFirstThenSecond() throws {
    let t1 = Date(timeIntervalSinceReferenceDate: 100)
    let t2 = Date(timeIntervalSinceReferenceDate: 200)
    let t3 = Date(timeIntervalSinceReferenceDate: 300)
    let t4 = Date(timeIntervalSinceReferenceDate: 400)

    let (first, second) = makeDrivePair()
    let p1 = makePosition(timestamp: t1)
    let p2 = makePosition(timestamp: t2)
    let p3 = makePosition(timestamp: t3)
    let p4 = makePosition(timestamp: t4)
    context!.insert(p1); context!.insert(p2)
    context!.insert(p3); context!.insert(p4)
    first.positions = [p1, p2]
    second.positions = [p3, p4]

    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")

    let merged = try fetchMerged(excluding: [first.id, second.id])
    let timestamps = merged?.orderedPositions.map(\.timestamp)
    #expect(timestamps == [t1, t2, t3, t4])
  }

  // MARK: - merge persistence

  @Test
  func mergeInsertsNewDriveIntoContext() throws {
    let (first, second) = makeDrivePair()
    let beforeCount = try context!.fetchCount(FetchDescriptor<Drive>())
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let afterCount = try context!.fetchCount(FetchDescriptor<Drive>())
    #expect(afterCount == beforeCount - 1)
  }

  @Test
  func mergeDeletesOriginalDrives() throws {
    let (first, second) = makeDrivePair()
    let firstID = first.id
    let secondID = second.id
    makeService().merge(orderedDrives: [first, second], mergedName: "Trip")
    let remaining = try count(where: #Predicate<Drive> { $0.id == firstID || $0.id == secondID })
    #expect(remaining == 0)
  }

  // MARK: - guard clause

  @Test
  func mergeIsNoOpWithOneDrive() throws {
    let drive = Drive(name: "Solo")
    context!.insert(drive)
    let beforeCount = try context!.fetchCount(FetchDescriptor<Drive>())
    makeService().merge(orderedDrives: [drive], mergedName: "Trip")
    let afterCount = try context!.fetchCount(FetchDescriptor<Drive>())
    #expect(afterCount == beforeCount)
  }

  @Test
  func mergeIsNoOpWithThreeDrives() throws {
    let d1 = Drive(name: "A"); let d2 = Drive(name: "B"); let d3 = Drive(name: "C")
    context!.insert(d1); context!.insert(d2); context!.insert(d3)
    let beforeCount = try context!.fetchCount(FetchDescriptor<Drive>())
    makeService().merge(orderedDrives: [d1, d2, d3], mergedName: "Trip")
    let afterCount = try context!.fetchCount(FetchDescriptor<Drive>())
    #expect(afterCount == beforeCount)
  }

  // MARK: - Helpers

  private func makeService() -> DriveMergeService {
    DriveMergeService(modelContext: context!)
  }

  private func makeDrivePair(
    firstStartedAt: Date = Date(timeIntervalSinceReferenceDate: 1000),
    firstEndedAt: Date? = Date(timeIntervalSinceReferenceDate: 2000),
    secondEndedAt: Date? = Date(timeIntervalSinceReferenceDate: 4000)
  ) -> (Drive, Drive) {
    let first = Drive(name: "First")
    first.startedAt = firstStartedAt
    first.endedAt = firstEndedAt
    first.status = .finished
    let second = Drive(name: "Second")
    second.startedAt = Date(timeIntervalSinceReferenceDate: 3000)
    second.endedAt = secondEndedAt
    second.status = .finished
    context!.insert(first)
    context!.insert(second)
    return (first, second)
  }

  private func makePosition(timestamp: Date) -> Position {
    Position(timestamp: timestamp, latitude: 51.5, longitude: -0.1,
             altitude: 10, horizontalAccuracy: 5, verticalAccuracy: 5,
             course: 0, courseAccuracy: 0, speed: 0, speedAccuracy: 0)
  }

  private func fetchMerged(excluding ids: [UUID]) throws -> Drive? {
    let all = try context!.fetch(FetchDescriptor<Drive>())
    return all.first { !ids.contains($0.id) }
  }
}
