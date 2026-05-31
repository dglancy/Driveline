//
//  ExportRouteBase.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import CoreLocation

// MARK: - Exporting route protocol

protocol ExportingRoute {
  func export(route: Route) async throws -> URL
}

// MARK: - Protocol extension

extension ExportingRoute {
  func validatedCoordinates(for route: Route) throws -> [CLLocationCoordinate2D] {
    let coords = route.positionLocationCoordinatesIn2D
    guard !coords.isEmpty else { throw ExportRouteError.emptyRoute }
    return coords
  }
}

// MARK: - Export route error enum

enum ExportRouteError: LocalizedError, Equatable {
  case emptyRoute

  var errorDescription: String? {
    switch self {
    case .emptyRoute:
      return String(localized: "Cannot export a route with no coordinates.", comment: "Export error: route has no recorded positions")
    }
  }
}

// MARK: - Export route file types

enum ExportFileType {
  case gpx
  case png

  var fileExtension: String {
    switch self {
    case .gpx:
      return "gpx"
    case .png:
      return "png"
    }
  }
}

// MARK: - Export route file naming service

struct ExportRouteFileNamingService {
  static let startedAtFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy'-'HHmm"
    formatter.timeZone = .current
    formatter.locale = .current
    return formatter
  }()

  static func fileURL(for route: Route, type: ExportFileType) -> URL {
    let filename = "\(startedAtFormatter.string(from: route.startedAt)).\(type.fileExtension)"
    return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
  }
}
