//
//  CinematicRoutePlanTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 21/11/2026.
//

@testable import Driveline
import CoreLocation
import Foundation
import Testing

@Suite("CinematicRoutePlan")
@MainActor
struct CinematicRoutePlanTests {

  @Test
  func oneHourDriveProducesTwoMinutesAtThirtyTimesScale() {
    let start = Date(timeIntervalSince1970: 0)
    let plan = CinematicRoutePlan(samples: [
      sample(latitude: 53.0, longitude: -6.0, date: start),
      sample(latitude: 54.0, longitude: -6.0, date: start.addingTimeInterval(3_600))
    ])

    #expect(plan.duration == 120)
    #expect(plan.frameCount == 2_880)
  }

  @Test
  func framesUseCinematicFrameRate() {
    let start = Date(timeIntervalSince1970: 0)
    let plan = CinematicRoutePlan(samples: [
      sample(latitude: 53.0, longitude: -6.0, date: start),
      sample(latitude: 53.1, longitude: -6.0, date: start.addingTimeInterval(600))
    ])

    #expect(plan.frames().count == Int(plan.duration * 24))
  }

  @Test
  func routeEndpointTracksCarAcrossUnevenSampleIntervals() {
    let start = Date(timeIntervalSince1970: 0)
    let plan = CinematicRoutePlan(samples: [
      sample(latitude: 53.00, longitude: -6.0, date: start),
      sample(latitude: 53.01, longitude: -6.0, date: start.addingTimeInterval(1)),
      sample(latitude: 53.02, longitude: -6.0, date: start.addingTimeInterval(2)),
      sample(latitude: 53.03, longitude: -6.0, date: start.addingTimeInterval(3)),
      sample(latitude: 54.00, longitude: -6.0, date: start.addingTimeInterval(100))
    ])
    let frames = plan.frames()
    let middleFrame = frames[frames.count / 2]

    #expect(middleFrame.completedSampleIndex == 3)
    #expect(middleFrame.coordinate.latitude > 53.03)
  }

  @Test
  func headingChangesAreSmoothedAcrossSharpTurn() throws {
    let start = Date(timeIntervalSince1970: 0)
    let plan = CinematicRoutePlan(samples: [
      sample(latitude: 53.0, longitude: -6.0, date: start),
      sample(latitude: 53.01, longitude: -6.0, date: start.addingTimeInterval(120)),
      sample(latitude: 53.01, longitude: -5.99, date: start.addingTimeInterval(240))
    ])
    let headings = plan.frames().map(\.heading)
    let changes = zip(headings, headings.dropFirst()).map { start, end in
      abs((end - start + 540).truncatingRemainder(dividingBy: 360) - 180)
    }

    #expect(try #require(changes.max()) < 5)
  }

  @Test
  func cameraYawObeysSpeedAndAccelerationLimits() throws {
    let start = Date(timeIntervalSince1970: 0)
    let plan = CinematicRoutePlan(samples: [
      sample(latitude: 53.0, longitude: -6.0, date: start),
      sample(latitude: 53.01, longitude: -6.0, date: start.addingTimeInterval(120)),
      sample(latitude: 53.01, longitude: -5.99, date: start.addingTimeInterval(240))
    ])
    let headings = plan.frames().map(\.heading)
    let velocities = zip(headings, headings.dropFirst()).map { start, end in
      ((end - start + 540).truncatingRemainder(dividingBy: 360) - 180) * 24
    }
    let accelerations = zip(velocities, velocities.dropFirst()).map { start, end in
      (end - start) * 24
    }

    #expect(try #require(velocities.map(abs).max()) <= CinematicRoutePlan.maximumYawSpeed + 0.001)
    #expect(try #require(accelerations.map(abs).max()) <= CinematicRoutePlan.maximumYawAcceleration + 0.001)
  }

  @Test
  func singlePointStillProducesAPlayableClip() {
    let plan = CinematicRoutePlan(samples: [
      sample(latitude: 53.0, longitude: -6.0, date: .now)
    ])

    #expect(plan.duration == 2)
    #expect(plan.frames().count == 48)
  }

  private func sample(
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees,
    date: Date
  ) -> CinematicRouteSample {
    CinematicRouteSample(
      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
      timestamp: date
    )
  }
}
