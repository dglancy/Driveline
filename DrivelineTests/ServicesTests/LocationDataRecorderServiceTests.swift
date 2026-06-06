//
//  LocationDataRecorderServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 30/05/2026.
//

@testable import Driveline
import Combine
import CoreLocation
import Foundation
import SwiftData
import Testing

@MainActor
final class LocationDataRecorderServiceTests: SwiftDataBaseTestCase {

  // MARK: - Tests

  @Test
  func startCreatesDrive() async throws {
    let drive = Drive(name: "Test drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    try recorder.startRecording(with: drive)

    #expect(recorder.drive != nil)
  }

  @Test
  func persistingLocationsAppendsPositions() async throws {
    let drive = Drive(name: "Test drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    try recorder.startRecording(with: drive)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    let drivePositions = recorder.drive!.orderedPositions.count
    #expect(drivePositions == 1)

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 1)
  }

  @Test
  func doesNotPersistLocationsBeforeRecordingStarts() async throws {
    let locationService = LocationService()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 0)
  }

  @Test
  func stopEndsRecordingDrive() async throws {
    let drive = Drive(name: "Test drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    try recorder.startRecording(with: drive)
    recorder.stopRecording()

    #expect(recorder.drive == nil)
  }

  @Test
  func flushesPositionsOnStop() async throws {
    let drive = Drive(name: "Test drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    try recorder.startRecording(with: drive)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)
    recorder.stopRecording()

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 1)
  }

  @Test
  func flushesPositionsOnTimerInterval() async throws {
    let drive = Drive(name: "Test drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!, saveInterval: 0.1)

    try recorder.startRecording(with: drive)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    try await Task.sleep(for: .milliseconds(200))

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 1)
  }

  @Test
  func startRecordingWithAlreadyPersistedDriveDoesNotDuplicateInStore() async throws {
    let drive = Drive(name: "Existing drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    context!.insert(drive)
    try context!.save()

    try recorder.startRecording(with: drive)

    #expect(recorder.drive != nil)
    let driveCount = try! count(where: #Predicate<Drive> { _ in true })
    #expect(driveCount == 1)

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    #expect(recorder.drive!.orderedPositions.count == 1)
  }

  @Test
  func doesNotPersistLocationsAfterRecordingStops() async throws {
    let drive = Drive(name: "Test drive")
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)

    try recorder.startRecording(with: drive)
    recorder.stopRecording()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 55.0, longitude: -4.0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 10, speedAccuracy: 0.5, timestamp: Date())
    locationService.locationPublisher.send(location)

    let persistedPositions = try! count(where: #Predicate<Position> { _ in true })
    #expect(persistedPositions == 0)
  }
}
