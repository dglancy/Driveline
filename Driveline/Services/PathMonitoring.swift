//
//  PathMonitoring.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Network

protocol PathMonitoring: AnyObject {
  var onPathUpdate: (@Sendable (Bool) -> Void)? { get set }
  func start(queue: DispatchQueue)
}

final class NWPathMonitorAdapter: PathMonitoring {

  // MARK: - Properties

  var onPathUpdate: (@Sendable (Bool) -> Void)?
  private let monitor = NWPathMonitor()

  // MARK: - Lifecycle

  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      let connected = path.status == .satisfied
      Task { @MainActor [weak self] in
        self?.onPathUpdate?(connected)
      }
    }
  }

  // MARK: - PathMonitoring

  func start(queue: DispatchQueue) {
    monitor.start(queue: queue)
  }
}
