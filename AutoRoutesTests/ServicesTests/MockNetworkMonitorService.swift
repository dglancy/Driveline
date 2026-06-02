//
//  MockNetworkMonitorService.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 01/06/2026.
//

@testable import AutoRoutes
import Combine
import Foundation

@MainActor
final class MockNetworkMonitorService: NetworkMonitorServiceProtocol {

  // MARK: - Properties

  var isConnected = false

  private let connectivityRestoredSubject = PassthroughSubject<Void, Never>()
  var connectivityRestoredPublisher: AnyPublisher<Void, Never> {
    connectivityRestoredSubject.eraseToAnyPublisher()
  }

  // MARK: - Test Support

  func simulateConnectivityRestored() {
    isConnected = true
    connectivityRestoredSubject.send()
  }
}
