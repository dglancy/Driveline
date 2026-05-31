//
//  ExportRouteServiceBase.swift
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

// MARK: - Export route error enum

enum ExportRouteError: LocalizedError, Equatable {
  case emptyRoute

  var errorDescription: String? {
    switch self {
    case .emptyRoute:
      return "Cannot export a route with no coordinates."
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
  private static let startedAtFormatter: DateFormatter = {
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

// MARK: - Export route service

class ExportRouteBase: ExportingRoute {

  func export(route: Route) async throws -> URL {
    fatalError("Subclasses must implement export(route:)")
  }

  func coordinates(for route: Route) throws -> [CLLocationCoordinate2D] {
    let coordinates = route.positionLocationCoordinatesIn2D
    guard !coordinates.isEmpty else { throw ExportRouteError.emptyRoute }
    return coordinates
  }
}
