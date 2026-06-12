//
//  DriveExportTransferable.swift
//  Driveline
//
//  Created by Damien Glancy on 10/06/2026.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

// MARK: - UTType

extension UTType {
  nonisolated static let gpx = UTType("com.targatrips.driveline.gpx") ?? UTType(filenameExtension: "gpx", conformingTo: .xml) ?? .xml
}

// MARK: - GPX export

struct DriveGPXExport: Transferable {
  nonisolated(unsafe) let drive: Drive

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .gpx) { export in
      let url = try await ExportDriveGPX().export(drive: export.drive)
      return try Data(contentsOf: url)
    }
  }
}

// MARK: - PNG export

struct DrivePNGExport: Transferable {
  nonisolated(unsafe) let drive: Drive

  static var transferRepresentation: some TransferRepresentation {
    DataRepresentation(exportedContentType: .png) { export in
      let url = try await ExportDrivePNG().export(drive: export.drive)
      return try Data(contentsOf: url)
    }
  }
}
