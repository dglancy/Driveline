//
//  DriveMergeServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 17/06/2026.
//

@testable import Driveline
import Foundation
import SwiftData
import Testing

@MainActor
final class DriveMergeServiceTests: SwiftDataBaseTestCase {

  // MARK: - merge name

  @Test
  func mergeCreatesNewDriveWithCorrectName() async throws {
    let (first, second) = try makeDrivePair()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Long Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.name == "Long Trip")
  }

  // MARK: - merge dates

  @Test
  func mergeUsesFirstDriveStartedAt() async throws {
    let start = Date(timeIntervalSinceReferenceDate: 1000)
    let (first, second) = try makeDrivePair(firstStartedAt: start)
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.startedAt == start)
  }

  @Test
  func mergeUsesSecondDriveEndedAt() async throws {
    let end = Date(timeIntervalSinceReferenceDate: 5000)
    let (first, second) = try makeDrivePair(secondEndedAt: end)
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endedAt == end)
  }

  @Test
  func mergeFallsBackToFirstEndedAtWhenSecondEndedAtIsNil() async throws {
    let end = Date(timeIntervalSinceReferenceDate: 3000)
    let (first, second) = try makeDrivePair(firstEndedAt: end, secondEndedAt: nil)
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endedAt == end)
  }

  // MARK: - merge status

  @Test
  func mergeSetsStatusToFinished() async throws {
    let (first, second) = try makeDrivePair()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.status == .finished)
  }

  // MARK: - merge place names

  @Test
  func mergeUsesFirstDriveStartPlaceName() async throws {
    let (first, second) = try makeDrivePair()
    first.startPlaceName = "Home"
    second.startPlaceName = "Café"
    try context!.save()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.startPlaceName == "Home")
  }

  @Test
  func mergeUsesSecondDriveEndPlaceName() async throws {
    let (first, second) = try makeDrivePair()
    first.endPlaceName = "Midpoint"
    second.endPlaceName = "Office"
    try context!.save()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endPlaceName == "Office")
  }

  // MARK: - merge positions

  @Test
  func mergeConcatenatesPositionsFromFirstThenSecond() async throws {
    let t1 = Date(timeIntervalSinceReferenceDate: 100)
    let t2 = Date(timeIntervalSinceReferenceDate: 200)
    let t3 = Date(timeIntervalSinceReferenceDate: 300)
    let t4 = Date(timeIntervalSinceReferenceDate: 400)

    let (first, second) = try makeDrivePair()
    first.positions = [makePosition(timestamp: t1), makePosition(timestamp: t2)]
    second.positions = [makePosition(timestamp: t3), makePosition(timestamp: t4)]
    try context!.save()

    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })

    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.orderedPositions.map(\.timestamp) == [t1, t2, t3, t4])
  }

  // MARK: - merge persistence

  @Test
  func mergeReducesDriveCountByOne() async throws {
    let (first, second) = try makeDrivePair()
    let beforeCount = try freshContext().fetchCount(FetchDescriptor<Drive>())
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let afterCount = try freshContext().fetchCount(FetchDescriptor<Drive>())
    #expect(afterCount == beforeCount - 1)
  }

  @Test
  func mergeDeletesOriginalDrives() async throws {
    let (first, second) = try makeDrivePair()
    let firstID = first.id
    let secondID = second.id
    _ = await makeService().merge(firstID: firstID, secondID: secondID, mergedName: "Trip", onProgress: { _ in })
    let remaining = try freshContext().fetchCount(
      FetchDescriptor<Drive>(predicate: #Predicate { $0.id == firstID || $0.id == secondID })
    )
    #expect(remaining == 0)
  }

  @Test
  func mergeReturnsResultWithMergedAndDeletedIDs() async throws {
    let (first, second) = try makeDrivePair()
    let result = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(result?.mergedID == merged?.id)
    #expect(Set(result?.deletedIDs ?? []) == Set([first.id, second.id]))
  }

  // MARK: - accumulated distance

  @Test
  func mergeComputesAccumulatedDistanceFromCombinedPositions() async throws {
    let t1 = Date(timeIntervalSinceReferenceDate: 100)
    let t2 = Date(timeIntervalSinceReferenceDate: 200)
    let t3 = Date(timeIntervalSinceReferenceDate: 300)
    let t4 = Date(timeIntervalSinceReferenceDate: 400)

    let (first, second) = try makeDrivePair()
    first.positions = [
      makePosition(timestamp: t1, latitude: 51.5000, longitude: -0.1000),
      makePosition(timestamp: t2, latitude: 51.5010, longitude: -0.1000)
    ]
    second.positions = [
      makePosition(timestamp: t3, latitude: 51.5020, longitude: -0.1000),
      makePosition(timestamp: t4, latitude: 51.5030, longitude: -0.1000)
    ]
    try context!.save()

    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })

    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect((merged?.accumulatedDistanceMetres ?? 0) > 0)
    #expect(merged?.accumulatedDistanceMetres == merged?.distanceMetres)
  }

  // MARK: - merge weather

  @Test
  func mergeKeepsStartWeatherFromFirstDrive() async throws {
    let (first, second) = try makeDrivePair()
    first.weatherReadings = [makeWeather(type: .start, temperature: 10)]
    second.weatherReadings = [makeWeather(type: .end, temperature: 20)]
    try context!.save()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.startWeather?.temperatureCelsius == 10)
  }

  @Test
  func mergeKeepsEndWeatherFromSecondDrive() async throws {
    let (first, second) = try makeDrivePair()
    first.weatherReadings = [makeWeather(type: .start, temperature: 10)]
    second.weatherReadings = [makeWeather(type: .end, temperature: 20)]
    try context!.save()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect(merged?.endWeather?.temperatureCelsius == 20)
  }

  @Test
  func mergeWeatherReadingsCountIsAtMostTwo() async throws {
    let (first, second) = try makeDrivePair()
    first.weatherReadings = [makeWeather(type: .start, temperature: 10)]
    second.weatherReadings = [makeWeather(type: .end, temperature: 20)]
    try context!.save()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip", onProgress: { _ in })
    let merged = try fetchMerged(excluding: [first.id, second.id])
    #expect((merged?.weatherReadings?.count ?? 0) <= 2)
  }

  // MARK: - unresolvable IDs

  @Test
  func mergeReturnsNilAndChangesNothingWhenDriveMissing() async throws {
    let (first, _) = try makeDrivePair()
    let beforeCount = try freshContext().fetchCount(FetchDescriptor<Drive>())
    let result = await makeService().merge(firstID: first.id, secondID: UUID(), mergedName: "Trip", onProgress: { _ in })
    let afterCount = try freshContext().fetchCount(FetchDescriptor<Drive>())
    #expect(result == nil)
    #expect(afterCount == beforeCount)
  }

  // MARK: - progress

  @Test
  func mergeReportsMonotonicProgressEndingAtOne() async throws {
    let (first, second) = try makeDrivePair()
    let timestamps = (0..<600).map { Date(timeIntervalSinceReferenceDate: Double($0)) }
    first.positions = timestamps[0..<300].map { makePosition(timestamp: $0) }
    second.positions = timestamps[300..<600].map { makePosition(timestamp: $0) }
    try context!.save()

    let collector = ProgressCollector()
    _ = await makeService().merge(firstID: first.id, secondID: second.id, mergedName: "Trip") { fraction in
      collector.append(fraction)
    }

    let values = collector.values
    #expect(!values.isEmpty)
    #expect(values.last == 1)
    #expect(values == values.sorted())
  }

  // MARK: - Helpers

  private func makeService() -> DriveMergeService {
    DriveMergeService(modelContainer: container!)
  }

  private func freshContext() -> ModelContext {
    ModelContext(container!)
  }

  private func makeDrivePair(
    firstStartedAt: Date = Date(timeIntervalSinceReferenceDate: 1000),
    firstEndedAt: Date? = Date(timeIntervalSinceReferenceDate: 2000),
    secondEndedAt: Date? = Date(timeIntervalSinceReferenceDate: 4000)
  ) throws -> (Drive, Drive) {
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
    try context!.save()
    return (first, second)
  }

  private func makePosition(timestamp: Date, latitude: Double = 51.5, longitude: Double = -0.1) -> Position {
    Position(timestamp: timestamp, latitude: latitude, longitude: longitude,
             altitude: 10, horizontalAccuracy: 5, verticalAccuracy: 5,
             course: 0, courseAccuracy: 0, speed: 0, speedAccuracy: 0)
  }

  private func makeWeather(type: Weather.WeatherType, temperature: Double) -> Weather {
    Weather(temperatureCelsius: temperature, conditionDescription: "Clear", symbolName: "sun.max", type: type)
  }

  private func fetchMerged(excluding ids: [UUID]) throws -> Drive? {
    let all = try freshContext().fetch(FetchDescriptor<Drive>())
    return all.first { !ids.contains($0.id) }
  }
}

// MARK: - ProgressCollector

private final class ProgressCollector: @unchecked Sendable {
  private let lock = NSLock()
  private var storage: [Double] = []

  var values: [Double] {
    lock.withLock { storage }
  }

  func append(_ value: Double) {
    lock.withLock { storage.append(value) }
  }
}
