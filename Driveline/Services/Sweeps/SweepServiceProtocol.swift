//
//  SweepServiceProtocol.swift
//  Driveline
//
//  Created by Damien Glancy on 07/06/2026.
//

protocol SweepServiceProtocol: Sendable {
  
  // MARK: - Properties
  
  nonisolated var taskIdentifier: String { get }
  
  // MARK: - Actions
  
  func sweep() async
}
