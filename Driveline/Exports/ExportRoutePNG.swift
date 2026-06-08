//
//  ExportDrivePNG.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import MapKit
import UIKit

// MARK: - PNG export service

final class ExportDrivePNG: ExportingDrive {

  // MARK: - Properties

  private let preferences: UserPreferences

  // MARK: - Lifecycle

  init(preferences: UserPreferences = UserPreferences()) {
    self.preferences = preferences
  }

  // MARK: - Actions

  func export(drive: Drive) async throws -> URL {
    Log.ui.info("A drive was selected for PNG export: \(drive.startedAt)")

    let coordinates = try validatedCoordinates(for: drive)
    let mapSize = preferences.exportMapSize

    let options = MKMapSnapshotter.Options()
    options.region = .fitting(coordinates, aspectRatio: mapSize.width / max(mapSize.height, 0.0001))
    options.size = mapSize
    options.scale = UITraitCollection.current.displayScale
    if preferences.alwaysUseLightMapAppearance {
      options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }
    options.pointOfInterestFilter = .excludingAll

    let snapshot = try await takeSnapshot(with: options, drive: drive)
    let image = renderSnapshotImage(snapshot, coordinates: coordinates, drive: drive)

    guard let pngData = image.pngData() else {
      throw ExportError.pngDataPreparationFailure
    }

    let fileURL = ExportDriveFileNamingService.fileURL(for: drive, type: .png)

    do {
      try pngData.write(to: fileURL, options: .atomic)
      return fileURL
    } catch {
      Log.ui.error("Failed to write PNG for drive: \(drive.startedAt) — error: \(error.localizedDescription)")
      throw ExportError.pngFileWriteFailure
    }
  }

  // MARK: - Private functions

  private func renderSnapshotImage(_ snapshot: MKMapSnapshotter.Snapshot, coordinates: [CLLocationCoordinate2D], drive: Drive) -> UIImage {
    let image = snapshot.image
    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

    return renderer.image { _ in
      image.draw(at: .zero)

      let polylinePath = UIBezierPath()
      for (index, coordinate) in coordinates.enumerated() {
        let point = snapshot.point(for: coordinate)
        if index == 0 {
          polylinePath.move(to: point)
        } else {
          polylinePath.addLine(to: point)
        }
      }

      UIColor.systemBlue.setStroke()
      polylinePath.lineWidth = preferences.driveWidth
      polylinePath.lineCapStyle = .round
      polylinePath.lineJoinStyle = .round
      polylinePath.stroke()

      let markerRenderer = MarkerRenderer()
      if let startCoordinate = coordinates.first {
        markerRenderer.draw(at: snapshot.point(for: startCoordinate), color: .systemGreen, systemName: Icons.Drive.startMarker,
                            label: drive.startPlaceName ?? String(localized: "Start", comment: "Export PNG start marker label"))
      }

      if let endCoordinate = coordinates.last {
        markerRenderer.draw(at: snapshot.point(for: endCoordinate), color: .systemBlue, systemName: Icons.Drive.finishFlag,
                            label: drive.endPlaceName ?? String(localized: "Finish", comment: "Export PNG finish marker label"))
      }
    }
  }

  private func takeSnapshot(with options: MKMapSnapshotter.Options, drive: Drive) async throws -> MKMapSnapshotter.Snapshot {
    let box: SnapshotBox = try await withCheckedThrowingContinuation { continuation in
      MKMapSnapshotter(options: options).start { snapshot, error in
        if let error {
          Log.ui.error("Failed to create PNG snapshot for drive: \(drive.startedAt) — error: \(error.localizedDescription)")
          continuation.resume(throwing: ExportError.pngSnapshotFailure)
          return
        }

        guard let snapshot else {
          continuation.resume(throwing: ExportError.pngSnapshotFailure)
          return
        }

        continuation.resume(returning: SnapshotBox(snapshot))
      }
    }
    return box.snapshot
  }

}

// MARK: - MapSize enum

enum MapSize: String {
  case low
  case medium
  case high1
  case high2
  case highest

  var size: CGSize {
    switch self {
    case .low: return CGSize(width: 800, height: 600)
    case .medium: return CGSize(width: 1024, height: 768)
    case .high1: return CGSize(width: 1600, height: 1200)
    case .high2: return CGSize(width: 1920, height: 1080)
    case .highest: return CGSize(width: 2400, height: 1800)
    }
  }

  init?(from string: String) {
    let key = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    self.init(rawValue: key)
  }

}

// MARK: - DriveWidth enum

enum DriveWidth: String {
  case thin
  case medium
  case thick

  var width: CGFloat {
    switch self {
    case .thin: return 3.0
    case .medium: return 6.0
    case .thick: return 9.0
    }
  }

  init?(from string: String) {
    let key = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    self.init(rawValue: key)
  }
}

// MARK: - SnapshotBox

// Snapshot is immutable after creation; safe to cross actors
private final class SnapshotBox: @unchecked Sendable {
  let snapshot: MKMapSnapshotter.Snapshot
  init(_ snapshot: MKMapSnapshotter.Snapshot) { self.snapshot = snapshot }
}
