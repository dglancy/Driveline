//
//  NetworkMonitorService.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Combine
import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitorService {

  // MARK: - Properties

  private(set) var isConnected = false

  @ObservationIgnored private let connectivityRestoredSubject = PassthroughSubject<Void, Never>()
  var connectivityRestoredPublisher: AnyPublisher<Void, Never> {
    connectivityRestoredSubject.eraseToAnyPublisher()
  }

  @ObservationIgnored private let monitor = NWPathMonitor()
  @ObservationIgnored private let queue = DispatchQueue(
    label: "com.targatrips.AutoRoute.network-monitor",
    qos: .utility
  )
  @ObservationIgnored private var isInitialUpdate = true

  // MARK: - Lifecycle

  init() {
    monitor.pathUpdateHandler = { [weak self] path in
      let connected = path.status == .satisfied
      Task { @MainActor [weak self] in
        guard let self else { return }
        let wasConnected = self.isConnected
        self.isConnected = connected
        if !self.isInitialUpdate && connected && !wasConnected {
          self.connectivityRestoredSubject.send()
        }
        self.isInitialUpdate = false
      }
    }
    monitor.start(queue: queue)
  }
}
