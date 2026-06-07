//
//  SweepServiceProtocol.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

@MainActor
protocol SweepServiceProtocol {
  nonisolated var taskIdentifier: String { get }
  func sweep() async
}
