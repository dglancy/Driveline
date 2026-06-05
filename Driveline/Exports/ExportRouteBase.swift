//
//  ExportDriveBase.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import CoreLocation

// MARK: - Exporting drive protocol

protocol ExportingDrive {
  func export(drive: Drive) async throws -> URL
}

// MARK: - Protocol extension

extension ExportingDrive {
  func validatedCoordinates(for drive: Drive) throws -> [CLLocationCoordinate2D] {
    let coords = drive.positionLocationCoordinatesIn2D
    guard !coords.isEmpty else { throw ExportError.emptyDrive }
    return coords
  }
}

// MARK: - Export error enum

enum ExportError: LocalizedError, Equatable {
  case emptyDrive
  case gpxEncodingFailed
  case pngSnapshotFailure
  case pngDataPreparationFailure
  case pngFileWriteFailure

  var errorDescription: String? {
    switch self {
    case .emptyDrive:
      return String(localized: "Cannot export a drive with no coordinates.", comment: "Export error: drive has no recorded positions")
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

// MARK: - Export drive file types

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

// MARK: - Export drive file naming service

struct ExportDriveFileNamingService {
  static let startedAtFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd-MMM-yyyy'-'HHmm"
    formatter.timeZone = .current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  static func fileURL(for drive: Drive, type: ExportFileType) -> URL {
    let filename = "\(startedAtFormatter.string(from: drive.startedAt)).\(type.fileExtension)"
    return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
  }
}
