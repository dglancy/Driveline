//
//  MetricKitService.swift
//  Driveline
//
//  Created by Damien Glancy on 13/06/2026.
//

import MetricKit

// MARK: - MetricKit Service

@MainActor
final class MetricKitService: NSObject, MXMetricManagerSubscriber {

  // MARK: - Lifecycle

  override init() {
    super.init()
  }

  func start() {
    MXMetricManager.shared.add(self)
    Log.metricKit.info("Subscribed to MetricKit payloads")
    logPastPayloads()
  }

  // MARK: - MXMetricManagerSubscriber

  nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
    payloads.forEach {
      Log.metricKit.debug("Received metric payload for period \($0.timeStampBegin) to \($0.timeStampEnd)")
    }
  }

  nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
    payloads.forEach {
      Log.metricKit.info("Received diagnostic payload for period \($0.timeStampBegin) to \($0.timeStampEnd)")
    }
  }

  // MARK: - Private

  private func logPastPayloads() {
    let metricPayloads = MXMetricManager.shared.pastPayloads
    let diagnosticPayloads = MXMetricManager.shared.pastDiagnosticPayloads
    Log.metricKit.debug("Found \(metricPayloads.count) past metric payload(s) and \(diagnosticPayloads.count) past diagnostic payload(s)")
  }
}
