//
//  AppLogger.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.

import OSLog

// MARK: - Enum

enum LogPrivacy {
  case `public`
  case `private`
}

// MARK: - App Logger

struct AppLogger {
  private let logger: Logger
  private let category: String
  
  init(category: String) {
    self.logger = Logger(subsystem: Constants.App.bundleIdentifier, category: category)
    self.category = category
  }
  
  func info(_ message: String, privacy: LogPrivacy = .private) {
    log(level: .info, message: message, privacy: privacy)
  }
  
  func debug(_ message: String, privacy: LogPrivacy = .private) {
    log(level: .debug, message: message, privacy: privacy)
  }
  
  func error(_ message: String, privacy: LogPrivacy = .private) {
    log(level: .error, message: message, privacy: privacy)
  }
  
  // MARK: - Private functions
  
  private func log(level: OSLogType, message: String, privacy: LogPrivacy) {
    switch privacy {
    case .public:
      logger.log(level: level, "[\(category)] \(message, privacy: .public)")
    case .private:
      logger.log(level: level, "[\(category)] \(message, privacy: .private)")
    }
  }
}

// MARK: - Log Enum

enum Log {
  static let lifecycle = AppLogger(category: "Lifecycle")
  static let ui = AppLogger(category: "UI")
  static let location = AppLogger(category: "Location")
  static let data = AppLogger(category: "Data")
  static let intent = AppLogger(category: "Intent")
  static let settings = AppLogger(category: "Settings")
}
