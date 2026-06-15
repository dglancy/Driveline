//
//  MockLocationStreaming.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 15/06/2026.
//

@testable import Driveline
import CoreLocation
import Foundation

// MARK: - Mock Location Stream Provider

final class MockLocationStreamProvider: LocationStreaming {

  // MARK: - Properties

  private let stream: AsyncStream<CLLocation>
  private let continuation: AsyncStream<CLLocation>.Continuation

  // MARK: - Lifecycle

  init() {
    var continuation: AsyncStream<CLLocation>.Continuation!
    self.stream = AsyncStream { continuation = $0 }
    self.continuation = continuation
  }

  // MARK: - Functions

  func locations() -> AsyncStream<CLLocation> {
    stream
  }

  func send(_ location: CLLocation) {
    continuation.yield(location)
  }

  func finish() {
    continuation.finish()
  }
}

// MARK: - Mock Background Activity Session

final class MockBackgroundActivitySession: BackgroundActivitySession {

  // MARK: - Properties

  private(set) var invalidateCallCount = 0

  // MARK: - Functions

  func invalidate() {
    invalidateCallCount += 1
  }
}

// MARK: - Mock Background Activity Session Provider

@MainActor
final class MockBackgroundActivitySessionProvider: BackgroundActivitySessionProviding {

  // MARK: - Properties

  private(set) var beginCallCount = 0
  let session = MockBackgroundActivitySession()

  // MARK: - Functions

  func begin() -> any BackgroundActivitySession {
    beginCallCount += 1
    return session
  }
}
