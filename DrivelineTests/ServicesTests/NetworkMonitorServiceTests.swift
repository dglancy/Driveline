//
//  NetworkMonitorServiceTests.swift
//  AutoDriveTests
//
//  Created by Damien Glancy on 31/05/2026.
//

@testable import Driveline
import Combine
import Testing

@Suite("NetworkMonitorService")
@MainActor
struct NetworkMonitorServiceTests {

  // MARK: - isConnected

  @Test
  func launchOnlineSetsConnected() async {
    let mock = MockPathMonitor()
    let service = NetworkMonitorService(pathMonitor: mock)

    mock.simulate(connected: true)
    await Task.yield()

    #expect(service.isConnected)
  }

  @Test
  func launchOfflineSetsDisconnected() async {
    let mock = MockPathMonitor()
    let service = NetworkMonitorService(pathMonitor: mock)

    mock.simulate(connected: false)
    await Task.yield()

    #expect(!service.isConnected)
  }

  // MARK: - connectivityRestoredPublisher

  @Test
  func launchOnlineDoesNotEmit() async {
    let mock = MockPathMonitor()
    let service = NetworkMonitorService(pathMonitor: mock)
    var emissions = 0
    let cancellable = service.connectivityRestoredPublisher.sink { emissions += 1 }
    defer { cancellable.cancel() }

    mock.simulate(connected: true)
    await Task.yield()

    #expect(emissions == 0)
  }

  @Test
  func dropThenRestoreEmits() async {
    let mock = MockPathMonitor()
    let service = NetworkMonitorService(pathMonitor: mock)
    var emissions = 0
    let cancellable = service.connectivityRestoredPublisher.sink { emissions += 1 }
    defer { cancellable.cancel() }

    mock.simulate(connected: true)
    await Task.yield()
    mock.simulate(connected: false)
    await Task.yield()
    mock.simulate(connected: true)
    await Task.yield()

    #expect(emissions == 1)
  }

  @Test
  func launchOfflineThenConnectEmits() async {
    let mock = MockPathMonitor()
    let service = NetworkMonitorService(pathMonitor: mock)
    var emissions = 0
    let cancellable = service.connectivityRestoredPublisher.sink { emissions += 1 }
    defer { cancellable.cancel() }

    mock.simulate(connected: false)
    await Task.yield()
    mock.simulate(connected: true)
    await Task.yield()

    #expect(emissions == 1)
  }

  @Test
  func repeatedConnectedWithoutDropDoesNotEmitAgain() async {
    let mock = MockPathMonitor()
    let service = NetworkMonitorService(pathMonitor: mock)
    var emissions = 0
    let cancellable = service.connectivityRestoredPublisher.sink { emissions += 1 }
    defer { cancellable.cancel() }

    mock.simulate(connected: false)
    await Task.yield()
    mock.simulate(connected: true)
    await Task.yield()
    mock.simulate(connected: true)
    await Task.yield()

    #expect(emissions == 1)
  }
}
