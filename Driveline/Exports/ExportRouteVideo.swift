//
//  ExportRouteVideo.swift
//  Driveline
//
//  Created by Damien Glancy on 21/11/2026.
//

import AVFoundation
import CoreVideo
import MapKit
import UIKit

@MainActor
final class ExportDriveVideo: ExportingDrive {

  // MARK: - Properties

  private let preferences: UserPreferences

  // MARK: - Lifecycle

  init(preferences: UserPreferences = UserPreferences()) {
    self.preferences = preferences
  }

  // MARK: - Actions

  func export(drive: Drive) async throws -> URL {
    Log.ui.info("A drive was selected for MP4 export: \(drive.startedAt)")
    let positions = drive.orderedPositions
    guard !positions.isEmpty else { throw ExportError.emptyDrive }

    let samples = positions.map {
      CinematicRouteSample(coordinate: $0.location.coordinate, timestamp: $0.timestamp)
    }
    let plan = CinematicRoutePlan(samples: samples)
    let frames = plan.frames()
    guard !frames.isEmpty else { throw ExportError.videoPreparationFailure }

    let outputURL = ExportDriveFileNamingService.fileURL(for: drive, type: .mp4)
    try? FileManager.default.removeItem(at: outputURL)
    try await encode(frames: frames, coordinates: samples.map(\.coordinate), outputURL: outputURL)
    return outputURL
  }

  // MARK: - Private

  private func encode(
    frames: [CinematicRouteFrame],
    coordinates: [CLLocationCoordinate2D],
    outputURL: URL
  ) async throws {
    let size = evenSize(preferences.exportMapSize)
    let writer: AVAssetWriter
    do {
      writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    } catch {
      throw ExportError.videoPreparationFailure
    }

    let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings(for: size))
    let rawAttributes: [String: any Sendable] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: Int(size.width),
      kCVPixelBufferHeightKey as String: Int(size.height)
    ]
    let pixelBufferAttributes = CVPixelBufferAttributes(rawAttributes: rawAttributes)
    guard let creationAttributes = CVPixelBufferCreationAttributes(pixelBufferAttributes) else {
      throw ExportError.videoPreparationFailure
    }
    let receiver = writer.inputPixelBufferReceiver(for: input, pixelBufferAttributes: creationAttributes)
    do {
      try writer.start()
    } catch {
      throw ExportError.videoEncodingFailure
    }
    writer.startSession(atSourceTime: .zero)

    for (index, frame) in frames.enumerated() {
      guard let pool = receiver.pixelBufferPool else {
        writer.cancelWriting()
        throw ExportError.videoEncodingFailure
      }
      do {
        let mutableBuffer = try pool.makeMutablePixelBuffer()
        try VideoPixelBufferRenderer.draw(
          try await image(for: frame, coordinates: coordinates, size: size),
          into: mutableBuffer
        )
        let presentationTime = CMTime(value: CMTimeValue(index), timescale: CMTimeScale(CinematicRoutePlan.framesPerSecond))
        try await receiver.append(CVReadOnlyPixelBuffer(mutableBuffer), with: presentationTime)
      } catch {
        writer.cancelWriting()
        throw ExportError.videoEncodingFailure
      }
    }

    receiver.finish()
    await writer.finishWriting()
    guard writer.status == .completed else { throw ExportError.videoEncodingFailure }
  }

  private func videoSettings(for size: CGSize) -> [String: Any] {
    [
      AVVideoCodecKey: AVVideoCodecType.hevc,
      AVVideoWidthKey: Int(size.width),
      AVVideoHeightKey: Int(size.height),
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: Int(size.width * size.height * 5),
        AVVideoExpectedSourceFrameRateKey: CinematicRoutePlan.framesPerSecond
      ]
    ]
  }

  private func image(
    for frame: CinematicRouteFrame,
    coordinates: [CLLocationCoordinate2D],
    size: CGSize
  ) async throws -> UIImage {
    let options = MKMapSnapshotter.Options()
    options.size = size
    options.scale = 1
    options.camera = MKMapCamera(
      lookingAtCenter: frame.cameraCenter,
      fromDistance: 900,
      pitch: 58,
      heading: frame.heading
    )
    options.pointOfInterestFilter = .excludingAll
    if preferences.alwaysUseLightMapAppearance {
      options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }

    let snapshot: MKMapSnapshotter.Snapshot
    do {
      snapshot = try await MKMapSnapshotter(options: options).start()
    } catch {
      throw ExportError.videoPreparationFailure
    }

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: size, format: format).image { _ in
      snapshot.image.draw(in: CGRect(origin: .zero, size: size))
      drawRoute(in: snapshot, coordinates: coordinates, frame: frame)
      VideoVehicleMarkerRenderer.draw(at: snapshot.point(for: frame.coordinate))
    }
  }

  private func drawRoute(
    in snapshot: MKMapSnapshotter.Snapshot,
    coordinates: [CLLocationCoordinate2D],
    frame: CinematicRouteFrame
  ) {
    guard !coordinates.isEmpty else { return }
    let lastIndex = min(coordinates.count - 1, frame.completedSampleIndex)
    let completedCoordinates = Array(coordinates[0...lastIndex]) + [frame.coordinate]
    let points = completedCoordinates.map(snapshot.point(for:))
    let visibleBounds = CGRect(origin: .zero, size: snapshot.image.size).insetBy(dx: -20, dy: -20)
    let segments = VideoRoutePathBuilder.visibleSegments(points: points, within: visibleBounds)

    UIColor.systemBlue.setStroke()
    for segment in segments {
      let path = UIBezierPath()
      path.move(to: segment[0])
      for point in segment.dropFirst() {
        path.addLine(to: point)
      }
      path.lineWidth = preferences.driveWidth
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      path.stroke()
    }
  }

  private func evenSize(_ size: CGSize) -> CGSize {
    CGSize(width: Int(size.width) / 2 * 2, height: Int(size.height) / 2 * 2)
  }
}

enum VideoRoutePathBuilder {

  static func visibleSegments(points: [CGPoint], within bounds: CGRect) -> [[CGPoint]] {
    var segments: [[CGPoint]] = []
    var currentSegment: [CGPoint] = []

    for point in points {
      guard point.x.isFinite, point.y.isFinite, bounds.contains(point) else {
        if currentSegment.count > 1 {
          segments.append(currentSegment)
        }
        currentSegment = []
        continue
      }
      currentSegment.append(point)
    }

    if currentSegment.count > 1 {
      segments.append(currentSegment)
    }
    return segments
  }
}

enum VideoVehicleMarkerRenderer {

  static let radius: CGFloat = 10

  static func markerRect(centeredAt point: CGPoint) -> CGRect {
    CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
  }

  static func draw(at point: CGPoint) {
    let path = UIBezierPath(ovalIn: markerRect(centeredAt: point))
    UIColor.systemBlue.setFill()
    path.fill()
    UIColor.white.setStroke()
    path.lineWidth = 3
    path.stroke()
  }
}

enum VideoPixelBufferRenderer {

  static let bitmapInfo: CGBitmapInfo = [
    .byteOrder32Little,
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
  ]

  static func draw(_ image: UIImage, into mutableBuffer: borrowing CVMutablePixelBuffer) throws {
    guard let cgImage = image.cgImage else { throw ExportError.videoEncodingFailure }
    try mutableBuffer.withUnsafeBuffer { buffer in
      CVPixelBufferLockBaseAddress(buffer, [])
      defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
      guard let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: CVPixelBufferGetWidth(buffer),
        height: CVPixelBufferGetHeight(buffer),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo.rawValue
      ) else { throw ExportError.videoEncodingFailure }
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)))
    }
  }
}
