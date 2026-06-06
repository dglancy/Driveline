//
//  NetworkMonitorService.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Combine
import Foundation
import Network
import Observation

// MARK: - Protocol

@MainActor
protocol NetworkMonitorServiceProtocol {
  var isConnected: Bool { get }
  var connectivityRestoredPublisher: AnyPublisher<Void, Never> { get }
}

// MARK: - NetworkMonitorService

@MainActor
@Observable
final class NetworkMonitorService: NetworkMonitorServiceProtocol {

  // MARK: - Properties

  private(set) var isConnected = false

  @ObservationIgnored private let connectivityRestoredSubject = PassthroughSubject<Void, Never>()
  var connectivityRestoredPublisher: AnyPublisher<Void, Never> {
    connectivityRestoredSubject.eraseToAnyPublisher()
  }

  @ObservationIgnored private let pathMonitor: any PathMonitoring
  @ObservationIgnored private let queue = DispatchQueue(
    label: "com.targatrips.driveline.network-monitor",
    qos: .utility
  )
  @ObservationIgnored private var hasSeenDisconnection = false

  // MARK: - Lifecycle

  init(pathMonitor: any PathMonitoring = NWPathMonitorAdapter()) {
    self.pathMonitor = pathMonitor
    pathMonitor.onPathUpdate = { [weak self] connected in
      Task { @MainActor [weak self] in
        guard let self else { return }
        let wasConnected = self.isConnected
        self.isConnected = connected
        if !connected {
          self.hasSeenDisconnection = true
        }
        if connected && !wasConnected && self.hasSeenDisconnection {
          self.connectivityRestoredSubject.send()
        }
      }
    }
    pathMonitor.start(queue: queue)
  }
}
