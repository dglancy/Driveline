//
//  DriveServiceTests.swift
//  AutoDriveTests
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
final class DriveServiceTests: SwiftDataBaseTestCase {

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

  @Test
  func startDriveResetsCurrentSpeedMs() async throws {
    let (service, _, _) = makeServices()

    try service.startDrive()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func startDriveGeneratesTimeBasedName() async throws {
    let (service, _, _) = makeServices()

    try service.startDrive()

    let validNames = ["Morning Drive", "Afternoon Drive", "Evening Drive", "Night Drive"]
    #expect(validNames.contains(service.drive!.name))
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
  func finishDriveResetsCurrentSpeedMs() async throws {
    let (service, locationService, _) = makeServices()

    try service.startDrive()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    service.finishDrive()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func finishDriveWithNoActiveDriveDoesNothing() async throws {
    let (service, _, _) = makeServices()

    service.finishDrive()

    #expect(service.drive == nil)
  }

  // MARK: - currentSpeedMs

  @Test
  func currentSpeedMsIsNilInitially() async throws {
    let (service, _, _) = makeServices()

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func currentSpeedMsUpdatesWhenLocationPublished() async throws {
    let (service, locationService, _) = makeServices()

    try service.startDrive()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)

    #expect(service.currentSpeedMs == 14.0)
  }

  @Test
  func currentSpeedMsIsNilForInvalidLocationSpeed() async throws {
    let (service, locationService, _) = makeServices()

    try service.startDrive()

    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: -1, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)

    #expect(service.currentSpeedMs == nil)
  }

  @Test
  func currentSpeedMsIsNilAfterFinishDrive() async throws {
    let (service, locationService, _) = makeServices()

    try service.startDrive()
    let location = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: 51.5, longitude: -0.1),
      altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5,
      course: 0, courseAccuracy: 1, speed: 14.0, speedAccuracy: 0.5, timestamp: Date()
    )
    locationService.locationPublisher.send(location)
    service.finishDrive()

    #expect(service.currentSpeedMs == nil)
  }

  // MARK: - initialDrive

  @Test
  func initialDriveIsSetOnInit() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let existingDrive = Drive(name: "Existing drive")
    let service = DriveService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialDrive: existingDrive)

    #expect(service.drive?.id == existingDrive.id)
  }

  @Test
  func initialDriveWithIsRecordingTrueSetsIsRecordingToTrue() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let drive = Drive(name: "Test")
    drive.status = .recording
    let service = DriveService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialDrive: drive)

    #expect(service.isRecording == true)
  }

  @Test
  func initialDriveWithIsRecordingFalseSetsIsRecordingToFalse() async throws {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let drive = Drive(name: "Test")
    drive.status = .finished
    let service = DriveService(modelContext: context!, locationService: locationService, locationDataRecorder: recorder, networkMonitorService: MockNetworkMonitorService(), initialDrive: drive)

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

  // MARK: - Helpers

  private func makeServices(geocodingService: (any GeocodingServiceProtocol)? = nil) -> (DriveService, LocationService, LocationDataRecorderService) {
    let locationService = LocationService()
    let recorder = LocationDataRecorderService(locationService: locationService, modelContext: context!)
    let service = DriveService(
      modelContext: context!,
      locationService: locationService,
      locationDataRecorder: recorder,
      geocodingService: geocodingService ?? MockGeocodingService(),
      networkMonitorService: MockNetworkMonitorService()
    )
    return (service, locationService, recorder)
  }
}
