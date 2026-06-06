//
//  DriveActivityService.swift
//  Driveline
//
//  Created by Damien Glancy on 06/06/2026.
//

#if os(iOS)
@preconcurrency import ActivityKit
import Foundation
import Observation

@MainActor
@Observable
final class DriveActivityService {

  // MARK: - Properties

  @ObservationIgnored private var activity: Activity<DriveActivityAttributes>?
  @ObservationIgnored private var lastContentState = DriveActivityAttributes.ContentState(
    startPlaceName: nil,
    distanceMetres: 0,
    avgSpeedMetresPerSecond: 0
  )

  // MARK: - Actions

  func startActivity(for drive: Drive) {
    let authInfo = ActivityAuthorizationInfo()
    Log.lifecycle.info("Live Activity: areActivitiesEnabled=\(authInfo.areActivitiesEnabled)")
    guard authInfo.areActivitiesEnabled else {
      Log.lifecycle.error("Live Activities are disabled — skipping request")
      return
    }
    let attributes = DriveActivityAttributes(startedAt: drive.startedAt)
    let contentState = DriveActivityAttributes.ContentState(
      startPlaceName: drive.startPlaceName,
      distanceMetres: 0,
      avgSpeedMetresPerSecond: 0
    )
    lastContentState = contentState
    let content = ActivityContent(state: contentState, staleDate: nil)
    do {
      activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
      Log.lifecycle.info("Live Activity started: id=\(self.activity?.id ?? "nil")")
    } catch {
      Log.lifecycle.error("Failed to start Live Activity: \(error)")
    }
  }

  func updateActivity(startPlaceName: String?, distanceMetres: Double, avgSpeedMetresPerSecond: Double) async {
    guard let activity else { return }
    let contentState = DriveActivityAttributes.ContentState(
      startPlaceName: startPlaceName,
      distanceMetres: distanceMetres,
      avgSpeedMetresPerSecond: avgSpeedMetresPerSecond
    )
    lastContentState = contentState
    await activity.update(ActivityContent(state: contentState, staleDate: nil))
  }

  func endActivity() async {
    guard let activity else { return }
    self.activity = nil
    await activity.end(ActivityContent(state: lastContentState, staleDate: nil), dismissalPolicy: .immediate)
  }
}
#endif
