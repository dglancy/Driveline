//
//  DriveRecordingServiceTests.swift
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
final class DriveRecordingServiceTests: SwiftDataBaseTestCase {

  // MARK: - startDrive

  @Test
  func startDriveCreatesRecordingDrive() async throws {
    let (service, locationService, recorder) = makeServices()

    try service.startDrive()

    #expect(service.drive != nil)
    #expect(service.drive!.isRecording == true)
    #expect(locationService.status == .started)
    #expect(recorder.drive != nil)
  }

  @Test
  func startDriveSetsIsRecordingToTrue() async throws {
    let (service, _, _) = makeServices()

    try service.startDrive()

    #expect(service.isRecording == true)
  }

  // MARK: - finishDrive

  @Test
  func finishDriveStopsRecordingAndPersists() async throws {
    let (service, locationService, recorder) = makeServices()

    try service.startDrive()
    let startedDrive = service.drive!
    service.finishDrive()

    #expect(locationService.status == .stopped)
    #expect(startedDrive.isRecording == false)
    #expect(startedDrive.endedAt != nil)
    #expect(recorder.drive == nil)

    let persistedCount = try! count(where: #Predicate<Drive> { _ in true })
    #expect(persistedCount == 1)
  }

  @Test
  func finishDriveSetsIsRecordingToFalse() async throws {
    let (service, _, _) = makeServices()

    try service.startDrive()
    service.finishDrive()

    #expect(service.isRecording == false)
  }

  @Test
  func finishDriveWithNoActiveDriveDoesNothing() async throws {
    let (service, _, _) = makeServices()

    service.finishDrive()

    #expect(service.drive == nil)
  }

  // MARK: - initialDrive

  @Test
  func initialDriveIsSetOnInit() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let existingDrive = Drive(name: "Existing drive")
    let service = DriveRecordingService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialDrive: existingDrive)

    #expect(service.drive?.id == existingDrive.id)
  }

  @Test
  func initialDriveWithIsRecordingTrueSetsIsRecordingToTrue() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let drive = Drive(name: "Test")
    drive.status = .recording
    let service = DriveRecordingService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialDrive: drive)

    #expect(service.isRecording == true)
  }

  @Test
  func initialDriveWithIsRecordingFalseSetsIsRecordingToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let drive = Drive(name: "Test")
    drive.status = .finished
    let service = DriveRecordingService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialDrive: drive)

    #expect(service.isRecording == false)
  }

  // MARK: - startDrive geocoding accuracy

  @Test
  func startDriveSetsStartPlaceNameFromAccurateLocation() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    try service.startDrive()

    let goodLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(goodLocation)

    await Task.yield()
    await Task.yield()

    #expect(service.drive?.startPlaceName == "Test Place")
  }

  @Test
  func startDriveGeocodesOnlyOnceEvenWithMultipleGoodLocations() async throws {
    let mockGeocoding = MockGeocodingService()
    let (service, locationService, _) = makeServices(geocodingService: mockGeocoding)

    try service.startDrive()

    let firstGood = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )
    let secondGood = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.502, longitude: -0.102),
      altitude: 0, horizontalAccuracy: 8, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 0, speedAccuracy: 0.5, timestamp: Date()
    )

    locationService.locationPublisher.send(firstGood)
    locationService.locationPublisher.send(secondGood)

    await Task.yield()
    await Task.yield()

    #expect(mockGeocoding.geocodedLocations.count == 1)
  }

  // MARK: - Continue drive if recently finished

  @Test
  func startDriveWithToggleOnResumesRecentlyFinishedDrive() async throws {
    let finishedDrive = try insertFinishedDrive(startPlaceName: "Home", endPlaceName: "Work")
    let (service, locationService, _) = makeServices(userPreferences: makePreferences(continueDriveIfRecentlyFinished: true))

    try service.startDrive(trigger: .automatic)

    #expect(service.drive?.id == finishedDrive.id)
    #expect(service.drive?.status == .recording)
    #expect(service.drive?.endedAt == nil)
    #expect(service.drive?.endPlaceName == nil)
    #expect(service.drive?.startPlaceName == "Home")
    #expect(locationService.status == .started)
  }

  @Test
  func startDriveWithToggleOnCreatesNewDriveIfNoneRecentlyFinished() async throws {
    let (service, _, _) = makeServices(userPreferences: makePreferences(continueDriveIfRecentlyFinished: true))

    try service.startDrive(trigger: .automatic)

    #expect(service.drive != nil)
    let driveCount = try count(where: #Predicate<Drive> { _ in true })
    #expect(driveCount == 1)
  }

  @Test
  func startDriveWithToggleOnCreatesNewDriveIfFinishedDriveIsOlderThan30Minutes() async throws {
    let oldDrive = try insertFinishedDrive(endedAt: .now.addingTimeInterval(-3600))
    let (service, _, _) = makeServices(userPreferences: makePreferences(continueDriveIfRecentlyFinished: true))

    try service.startDrive(trigger: .automatic)

    #expect(service.drive?.id != oldDrive.id)
    let driveCount = try count(where: #Predicate<Drive> { _ in true })
    #expect(driveCount == 2)
  }

  @Test
  func startDriveWithManualTriggerAlwaysCreatesNewDrive() async throws {
    try insertFinishedDrive()
    let (service, _, _) = makeServices(userPreferences: makePreferences(continueDriveIfRecentlyFinished: true))

    try service.startDrive(trigger: .manual)

    let driveCount = try count(where: #Predicate<Drive> { _ in true })
    #expect(driveCount == 2)
  }

  @Test
  func startDriveWithToggleOffAlwaysCreatesNewDrive() async throws {
    try insertFinishedDrive()
    let (service, _, _) = makeServices(userPreferences: makePreferences(continueDriveIfRecentlyFinished: false))

    try service.startDrive(trigger: .automatic)

    let driveCount = try count(where: #Predicate<Drive> { _ in true })
    #expect(driveCount == 2)
  }

  // MARK: - Helpers

  private func makeServices(geocodingService: (any GeocodingServiceProtocol)? = nil, userPreferences: UserPreferences? = nil) -> (DriveRecordingService, LocationService, LocationDataRecorderService) {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = DriveRecordingService(
      modelContext: context!,
      locationService: locationService,
      locationDataRecorder: recorder,
      geocodingService: geocodingService ?? MockGeocodingService(),
      networkMonitorService: MockNetworkMonitorService(),
      userPreferences: userPreferences ?? UserPreferences()
    )
    return (service, locationService, recorder)
  }

  @discardableResult
  private func insertFinishedDrive(endedAt: Date = .now, startPlaceName: String? = nil, endPlaceName: String? = nil) throws -> Drive {
    let drive = Drive(trigger: .automatic)
    drive.status = .finished
    drive.endedAt = endedAt
    drive.startPlaceName = startPlaceName
    drive.endPlaceName = endPlaceName
    context!.insert(drive)
    try context!.save()
    return drive
  }

  private func makePreferences(continueDriveIfRecentlyFinished: Bool) -> UserPreferences {
    let defaults = UserDefaults(suiteName: UUID().uuidString)!
    defaults.set(continueDriveIfRecentlyFinished, forKey: "ContinueDriveIfRecentlyFinished")
    return UserPreferences(defaults: defaults)
  }
}
