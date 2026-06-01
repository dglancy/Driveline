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
    guard !coords.isEmpty else { throw ExportError.emptyRoute }
    return coords
  }
}

// MARK: - Export error enum

enum ExportError: LocalizedError, Equatable {
  case emptyRoute
  case gpxEncodingFailed
  case pngSnapshotFailure
  case pngDataPreparationFailure
  case pngFileWriteFailure

  var errorDescription: String? {
    switch self {
    case .emptyRoute:
      return String(localized: "Cannot export a route with no coordinates.", comment: "Export error: route has no recorded positions")
    case .gpxEncodingFailed:
      return String(localized: "Failed to prepare GPX data for sharing.", comment: "Export error: GPX string could not be encoded as UTF-8")
    case .pngSnapshotFailure:
      return String(localized: "Failed to create PNG. Please try again.", comment: "Export error: map snapshot failed")
    case .pngDataPreparationFailure:
      return String(localized: "Failed to prepare PNG data for sharing.", comment: "Export error: UIImage could not produce PNG data")
    case .pngFileWriteFailure:
      return String(localized: "Failed to save PNG. Please try again.", comment: "Export error: writing PNG file to disk failed")
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
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  static func fileURL(for route: Route, type: ExportFileType) -> URL {
    let filename = "\(startedAtFormatter.string(from: route.startedAt)).\(type.fileExtension)"
    return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
  }
}
