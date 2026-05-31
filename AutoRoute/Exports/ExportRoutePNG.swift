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

// MARK: - PNG export error

enum ExportRoutePNGError: LocalizedError {
  case snapshotFailure(String)
  case dataPreparationFailure
  case fileWriteFailure(String)

  var errorDescription: String? {
    switch self {
    case .snapshotFailure(let message):
      return String(localized: "Failed to create PNG. Please try again.\n\nDetails: \(message)", comment: "Export error: map snapshot failed")
    case .dataPreparationFailure:
      return String(localized: "Failed to prepare PNG data for sharing.", comment: "Export error: UIImage could not produce PNG data")
    case .fileWriteFailure(let message):
      return String(localized: "Failed to save PNG. Please try again.\n\nDetails: \(message)",
                    comment: "Export error: writing PNG file to disk failed")
    }
  }
}

// MARK: - PNG export service

final class ExportRoutePNG: ExportingRoute {

  // MARK: - Actions

  func export(route: Route) async throws -> URL {
    Log.ui.info("A route was selected for PNG export: \(route.startedAt)")

    let coordinates = try validatedCoordinates(for: route)
    let mapSize = exportMapSizeFromSettings()

    let options = MKMapSnapshotter.Options()
    options.region = boundingRegion(for: coordinates, mapSize: mapSize)
    options.size = mapSize
    options.scale = UITraitCollection.current.displayScale
    if exportMapAlwaysUseLightAppearanceFromSettings() {
      options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }
    options.pointOfInterestFilter = .excludingAll

    let snapshot = try await takeSnapshot(with: options, route: route)
    let image = renderSnapshotImage(snapshot, coordinates: coordinates)

    guard let pngData = image.pngData() else {
      throw ExportRoutePNGError.dataPreparationFailure
    }

    let fileURL = ExportRouteFileNamingService.fileURL(for: route, type: .png)

    do {
      try pngData.write(to: fileURL, options: .atomic)
      return fileURL
    } catch {
      Log.ui.error("Failed to write PNG for route: \(route.startedAt) — error: \(error.localizedDescription)")
      throw ExportRoutePNGError.fileWriteFailure(error.localizedDescription)
    }
  }

  // MARK: - Private functions

  private func boundingRegion(for coordinates: [CLLocationCoordinate2D], mapSize: CGSize) -> MKCoordinateRegion {
    guard let first = coordinates.first else { return .init() }

    var minLat = first.latitude
    var maxLat = first.latitude
    var minLon = first.longitude
    var maxLon = first.longitude

    for coord in coordinates {
      minLat = min(minLat, coord.latitude)
      maxLat = max(maxLat, coord.latitude)
      minLon = min(minLon, coord.longitude)
      maxLon = max(maxLon, coord.longitude)
    }

    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                        longitude: (minLon + maxLon) / 2)

    let minimumSpan: CLLocationDegrees = 0.005
    let targetAspectRatio = mapSize.width / max(mapSize.height, 0.0001)
    let paddingMultiplier: CLLocationDegrees = 1.5

    let latitudeDelta = max(maxLat - minLat, minimumSpan) * paddingMultiplier
    let longitudeDelta = max(maxLon - minLon, minimumSpan) * paddingMultiplier

    let centerLatitudeRadians = center.latitude * .pi / 180
    let normalizedLongitudeDelta = longitudeDelta * cos(centerLatitudeRadians)

    var adjustedLongitudeDeltaNormalized = normalizedLongitudeDelta
    var adjustedLatitudeDelta = latitudeDelta

    if adjustedLongitudeDeltaNormalized / adjustedLatitudeDelta < targetAspectRatio {
      adjustedLongitudeDeltaNormalized = adjustedLatitudeDelta * targetAspectRatio
    } else {
      adjustedLatitudeDelta = adjustedLongitudeDeltaNormalized / targetAspectRatio
    }

    let longitudeScale = max(cos(centerLatitudeRadians), 0.0001)
    let adjustedLongitudeDelta = max(adjustedLongitudeDeltaNormalized / longitudeScale, minimumSpan)

    let span = MKCoordinateSpan(latitudeDelta: max(adjustedLatitudeDelta, minimumSpan),
                                longitudeDelta: adjustedLongitudeDelta)
    return MKCoordinateRegion(center: center, span: span)
  }

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
      polylinePath.lineWidth = exportMapRouteWidthFromSettings()
      polylinePath.lineCapStyle = .round
      polylinePath.lineJoinStyle = .round
      polylinePath.stroke()

      if let startCoordinate = coordinates.first {
        drawMarker(at: snapshot.point(for: startCoordinate), color: .systemGreen, systemName: "house.fill", label: "Start")
      }

      if let endCoordinate = coordinates.last {
        drawMarker(at: snapshot.point(for: endCoordinate), color: .systemBlue, systemName: "flag.pattern.checkered", label: "Finish")
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
    try await withCheckedThrowingContinuation { continuation in
      MKMapSnapshotter(options: options).start { snapshot, error in
        if let error {
          Log.ui.error("Failed to create PNG snapshot for route: \(route.startedAt) — error: \(error.localizedDescription)")
          continuation.resume(throwing: ExportRoutePNGError.snapshotFailure(error.localizedDescription))
          return
        }

        guard let snapshot else {
          continuation.resume(throwing: ExportRoutePNGError.snapshotFailure("Unknown error"))
          return
        }

        continuation.resume(returning: snapshot)
      }
    }
  }

  private func exportMapSizeFromSettings() -> CGSize {
    let rawValue = UserDefaults.standard.string(forKey: "ExportMapSize") ?? "high2"
    let size = MapSize.size(for: rawValue)
    Log.ui.info("Export map size set to \"\(rawValue)\" from user settings")
    return size
  }

  private func exportMapAlwaysUseLightAppearanceFromSettings() -> Bool {
    let alwaysUseLightAppearance = UserDefaults.standard.bool(forKey: "AlwaysUseLightMapAppearance")
    Log.ui.info("Always use light map appearance set to \"\(alwaysUseLightAppearance)\" from user settings")
    return alwaysUseLightAppearance
  }

  private func exportMapRouteWidthFromSettings() -> CGFloat {
    let rawValue = UserDefaults.standard.string(forKey: "RouteWidth") ?? "medium"
    let routeWidth = RouteWidth(from: rawValue) ?? RouteWidth.medium
    Log.ui.info("Route width set to \"\(routeWidth)\" from user settings")
    return routeWidth.width
  }
}

// MARK: - MapSize enum

enum MapSize: String, CaseIterable {
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

  static func size(for string: String, default defaultSize: MapSize = .high2) -> CGSize {
    MapSize(from: string)?.size ?? defaultSize.size
  }
}

// MARK: - RouteWidth enum

enum RouteWidth: String, CaseIterable {
  case thin
  case medium
  case thick

  var width: CGFloat {
    switch self {
    case .thin: return 2.0
    case .medium: return 6.0
    case .thick: return 10.0
    }
  }

  init?(from string: String) {
    let key = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    self.init(rawValue: key)
  }
}

// MARK: - MKMapSnapshotter.Snapshot extension

extension MKMapSnapshotter.Snapshot: @unchecked @retroactive Sendable {}
