//
//  MockPathMonitor.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Foundation

final class MockPathMonitor: PathMonitoring {

  // MARK: - Properties

  var onPathUpdate: (@Sendable (Bool) -> Void)?
  private(set) var started = false

  // MARK: - PathMonitoring

  func start(queue: DispatchQueue) {
    started = true
  }

  // MARK: - Test Support

  @MainActor func simulate(connected: Bool) {
    onPathUpdate?(connected)
  }
}
