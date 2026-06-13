//
//  MetricKitServiceTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 13/06/2026.
//

@testable import Driveline
import MetricKit
import Testing

@MainActor
final class MetricKitServiceTests {

  // MARK: - Lifecycle

  @Test
  func initializationDoesNotCrash() {
    _ = MetricKitService()
  }

  // MARK: - MXMetricManagerSubscriber

  @Test
  func didReceiveEmptyMetricPayloadsDoesNothing() {
    let service = MetricKitService()
    service.didReceive([MXMetricPayload]())
  }

  @Test
  func didReceiveEmptyDiagnosticPayloadsDoesNothing() {
    let service = MetricKitService()
    service.didReceive([MXDiagnosticPayload]())
  }
}
