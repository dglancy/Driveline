//
//  AppLogger.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.

import OSLog

// MARK: - App Logger

struct AppLogger {
  private let logger: Logger
  private let category: String

  init(subsystem: String = kAppBundleId, category: String) {
    self.logger = Logger(subsystem: subsystem, category: category)
    self.category = category
  }

  func info(_ message: String) {
    logger.info("[\(category)] \(message, privacy: .public)")
  }

  func debug(_ message: String) {
    logger.debug("[\(category)] \(message, privacy: .public)")
  }

  func error(_ message: String) {
    logger.error("[\(category)] \(message, privacy: .public)")
  }
}

// MARK: - Log Enum

enum Log {
  static let lifecycle = AppLogger(category: "Lifecycle")
  static let ui = AppLogger(category: "UI")
  static let location = AppLogger(category: "Location")
  static let data = AppLogger(category: "Data")
  static let intent = AppLogger(category: "Intent")
}
