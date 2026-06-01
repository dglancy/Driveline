//
//  ExportRoutePNG.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import MapKit
import UIKit
import os.log

// MARK: - PNG export service

final class ExportRoutePNG: ExportingRoute {

  // MARK: - Properties

  private let preferences: UserPreferences

  // MARK: - Lifecycle

  init(preferences: UserPreferences = UserPreferences()) {
    self.preferences = preferences
  }

  // MARK: - Actions

  func export(route: Route) async throws -> URL {
    Log.ui.info("A route was selected for PNG export: \(route.startedAt)")

    let coordinates = try validatedCoordinates(for: route)
    let mapSize = preferences.exportMapSize

    let options = MKMapSnapshotter.Options()
    options.region = .fitting(coordinates, aspectRatio: mapSize.width / max(mapSize.height, 0.0001))
    options.size = mapSize
    options.scale = UITraitCollection.current.displayScale
    if preferences.alwaysUseLightMapAppearance {
      options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }
    options.pointOfInterestFilter = .excludingAll

    let snapshot = try await takeSnapshot(with: options, route: route)
    let image = renderSnapshotImage(snapshot, coordinates: coordinates)

    guard let pngData = image.pngData() else {
      throw ExportError.pngDataPreparationFailure
    }

    let fileURL = ExportRouteFileNamingService.fileURL(for: route, type: .png)

    do {
      try pngData.write(to: fileURL, options: .atomic)
      return fileURL
    } catch {
      Log.ui.error("Failed to write PNG for route: \(route.startedAt) — error: \(error.localizedDescription)")
      throw ExportError.pngFileWriteFailure
    }
  }

  // MARK: - Private functions

  private func renderSnapshotImage(_ snapshot: MKMapSnapshotter.Snapshot, coordinates: [CLLocationCoordinate2D]) -> UIImage {
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
      polylinePath.lineWidth = preferences.routeWidth
      polylinePath.lineCapStyle = .round
      polylinePath.lineJoinStyle = .round
      polylinePath.stroke()

      if let startCoordinate = coordinates.first {
        drawMarker(at: snapshot.point(for: startCoordinate), color: .systemGreen, systemName: "house.fill",
                   label: String(localized: "Start", comment: "Export PNG start marker label"))
      }

      if let endCoordinate = coordinates.last {
        drawMarker(at: snapshot.point(for: endCoordinate), color: .systemBlue, systemName: "flag.pattern.checkered",
                   label: String(localized: "Finish", comment: "Export PNG finish marker label"))
      }
    }
  }

  private func drawMarker(at point: CGPoint, color: UIColor, systemName: String, label: String) {
    let outerRadius: CGFloat = 14
    let innerRadius: CGFloat = 11

    let outerRect = CGRect(x: point.x - outerRadius, y: point.y - outerRadius, width: outerRadius * 2, height: outerRadius * 2)
    let innerRect = CGRect(x: point.x - innerRadius, y: point.y - innerRadius, width: innerRadius * 2, height: innerRadius * 2)

    let outerPath = UIBezierPath(ovalIn: outerRect)
    UIColor.white.setFill()
    outerPath.fill()

    let innerPath = UIBezierPath(ovalIn: innerRect)
    color.setFill()
    color.setStroke()
    innerPath.lineWidth = 2
    innerPath.fill()
    innerPath.stroke()

    if let symbol = UIImage(systemName: systemName,
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?
      .withTintColor(.white, renderingMode: .alwaysOriginal) {
      let symbolOrigin = CGPoint(x: point.x - symbol.size.width / 2,
                                 y: point.y - symbol.size.height / 2)
      symbol.draw(in: CGRect(origin: symbolOrigin, size: symbol.size))
    }

    drawLabel(label, near: point, offsetFromMarker: outerRadius)
  }

  private func drawLabel(_ text: String, near point: CGPoint, offsetFromMarker markerRadius: CGFloat) {
    let horizontalPadding: CGFloat = 8
    let verticalPadding: CGFloat = 4
    let cornerRadius: CGFloat = 8
    let verticalOffset: CGFloat = 8

    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
      .foregroundColor: UIColor.label
    ]

    let textSize = (text as NSString).size(withAttributes: attributes)
    let backgroundSize = CGSize(width: textSize.width + horizontalPadding * 2,
                                height: textSize.height + verticalPadding * 2)

    let backgroundOrigin = CGPoint(x: point.x - backgroundSize.width / 2,
                                   y: point.y + markerRadius + verticalOffset)
    let backgroundRect = CGRect(origin: backgroundOrigin, size: backgroundSize)

    let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: cornerRadius)
    UIColor.systemBackground.setFill()
    UIColor.separator.setStroke()
    backgroundPath.lineWidth = 1
    backgroundPath.fill()
    backgroundPath.stroke()

    let textOrigin = CGPoint(x: backgroundRect.minX + horizontalPadding,
                             y: backgroundRect.minY + verticalPadding)
    (text as NSString).draw(at: textOrigin, withAttributes: attributes)
  }

  private func takeSnapshot(with options: MKMapSnapshotter.Options, route: Route) async throws -> MKMapSnapshotter.Snapshot {
    let box: SnapshotBox = try await withCheckedThrowingContinuation { continuation in
      MKMapSnapshotter(options: options).start { snapshot, error in
        if let error {
          Log.ui.error("Failed to create PNG snapshot for route: \(route.startedAt) — error: \(error.localizedDescription)")
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

// MARK: - RouteWidth enum

enum RouteWidth: String {
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

private final class SnapshotBox: @unchecked Sendable {
  let snapshot: MKMapSnapshotter.Snapshot
  init(_ snapshot: MKMapSnapshotter.Snapshot) { self.snapshot = snapshot }
}
