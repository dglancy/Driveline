//
//  AppBootstrap.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

import BackgroundTasks
import Foundation
import SwiftData

@MainActor
enum AppBootstrap {

  // MARK: - Boot

  static func boot(isUITesting: Bool = Self.isUITesting()) -> AppEnvironment {
    Log.lifecycle.info("App starting")
    let modelContainer = createModelContainer(inMemoryOnly: isUITesting)
    let locationService = setupLocationService()
    let locationDataRecorder = setupLocationDataRecorderService(
      locationService: locationService,
      modelContext: modelContainer.mainContext
    )
    let placeNameSweepService = PlaceNameSweepService(modelContext: modelContainer.mainContext)
    let weatherSweepService = WeatherSweepService(modelContext: modelContainer.mainContext)
    let driveService = setupDriveRecordingService(
      modelContext: modelContainer.mainContext,
      locationService: locationService,
      locationDataRecorder: locationDataRecorder,
      placeNameSweepService: placeNameSweepService,
      weatherSweepService: weatherSweepService
    )
    registerBGTasks([placeNameSweepService, weatherSweepService])
    registerIntentDependencies(driveService: driveService)
    if isUITesting { Log.lifecycle.info("Running in UI Testing mode") }
    Log.lifecycle.info("App started")
    return AppEnvironment(modelContainer: modelContainer, driveService: driveService, placeNameSweepService: placeNameSweepService, weatherSweepService: weatherSweepService)
  }

  // MARK: - Private

  private static func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains(Constants.Testing.UITestingFlag)
  }

  private static func createModelContainer(inMemoryOnly: Bool) -> ModelContainer {
    Log.lifecycle.info("Setting up data model and container")
    let schema = Schema([
      Drive.self,
      Position.self,
      Weather.self
    ])
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: inMemoryOnly,
      cloudKitDatabase: inMemoryOnly ? .none : .automatic
    )
    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }

  private static func setupLocationService() -> LocationService {
    Log.lifecycle.info("Setting up location services")
    return LocationService()
  }

  private static func setupLocationDataRecorderService(
    locationService: LocationService,
    modelContext: ModelContext
  ) -> LocationDataRecorderService {
    Log.lifecycle.info("Setting up location data recorder")
    return LocationDataRecorderService(locationService: locationService, modelContext: modelContext)
  }

  private static func setupDriveRecordingService(
    modelContext: ModelContext,
    locationService: LocationService,
    locationDataRecorder: LocationDataRecorderService,
    placeNameSweepService: PlaceNameSweepService,
    weatherSweepService: WeatherSweepService
  ) -> DriveRecordingService {
    Log.lifecycle.info("Setting up drive service")
    var descriptor = FetchDescriptor<Drive>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
    descriptor.fetchLimit = 1
    let activeDrive = (try? modelContext.fetch(descriptor))?.first.flatMap { $0.status != .finished ? $0 : nil }
    return DriveRecordingService(
      modelContext: modelContext,
      locationService: locationService,
      locationDataRecorder: locationDataRecorder,
      placeNameSweepService: placeNameSweepService,
      weatherSweepService: weatherSweepService,
      initialDrive: activeDrive
    )
  }

  private static func registerBGTasks(_ services: [any SweepServiceProtocol]) {
    services.forEach { registerBGTask($0) }
  }

  private static func registerBGTask(_ service: any SweepServiceProtocol) {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: service.taskIdentifier, using: nil) { task in
      guard let processingTask = task as? BGProcessingTask else {
        task.setTaskCompleted(success: false)
        return
      }
      let sweepTask = Task { @MainActor in
        await service.sweep()
        processingTask.setTaskCompleted(success: true)
      }
      processingTask.expirationHandler = {
        sweepTask.cancel()
        processingTask.setTaskCompleted(success: false)
      }
    }
  }

  private static func registerIntentDependencies(driveService: DriveRecordingService) {
    Log.lifecycle.info("Registering dependencies for App Intents")
    IntentDependencyResolver.provider = { driveService }
  }
}
