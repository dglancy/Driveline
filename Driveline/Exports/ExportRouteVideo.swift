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
  private let snapshotRetryPolicy = VideoSnapshotRetryPolicy()

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
    let configuration = VideoExportRenderConfiguration(
      size: evenSize(preferences.exportMapSize),
      driveWidth: preferences.driveWidth,
      alwaysUseLightMapAppearance: preferences.alwaysUseLightMapAppearance
    )
    let writerContext = try makeWriter(outputURL: outputURL, size: configuration.size)
    let writer = writerContext.writer
    let receiver = writerContext.receiver
    do {
      try writer.start()
    } catch {
      throw ExportError.videoEncodingFailure
    }
    writer.startSession(atSourceTime: .zero)

    for (index, frame) in frames.enumerated() {
      try await append(
        frame: frame,
        at: index,
        coordinates: coordinates,
        configuration: configuration,
        writerContext: writerContext
      )
    }

    receiver.finish()
    await writer.finishWriting()
    guard writer.status == .completed else { throw ExportError.videoEncodingFailure }
  }

  private func makeWriter(outputURL: URL, size: CGSize) throws -> VideoWriterContext {
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
    return VideoWriterContext(writer: writer, receiver: receiver)
  }

  private func append(
    frame: CinematicRouteFrame,
    at index: Int,
    coordinates: [CLLocationCoordinate2D],
    configuration: VideoExportRenderConfiguration,
    writerContext: VideoWriterContext
  ) async throws {
    let snapshot: MKMapSnapshotter.Snapshot
    do {
      snapshot = try await self.snapshot(for: frame, configuration: configuration)
    } catch {
      writerContext.writer.cancelWriting()
      throw error
    }
    guard let pool = writerContext.receiver.pixelBufferPool else {
      writerContext.writer.cancelWriting()
      throw ExportError.videoEncodingFailure
    }
    do {
      let buffer = try pool.makeMutablePixelBuffer()
      try VideoPixelBufferRenderer.draw(snapshot.image, into: buffer) {
        drawRoute(in: snapshot, coordinates: coordinates, frame: frame, driveWidth: configuration.driveWidth)
        VideoVehicleMarkerRenderer.draw(at: snapshot.point(for: frame.coordinate))
      }
      let time = CMTime(value: CMTimeValue(index), timescale: CMTimeScale(CinematicRoutePlan.framesPerSecond))
      try await writerContext.receiver.append(CVReadOnlyPixelBuffer(buffer), with: time)
    } catch {
      writerContext.writer.cancelWriting()
      throw ExportError.videoEncodingFailure
    }
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

  private func snapshot(
    for frame: CinematicRouteFrame,
    configuration: VideoExportRenderConfiguration
  ) async throws -> MKMapSnapshotter.Snapshot {
    let options = MKMapSnapshotter.Options()
    options.size = configuration.size
    options.scale = 1
    options.camera = MKMapCamera(
      lookingAtCenter: frame.cameraCenter,
      fromDistance: 900,
      pitch: 58,
      heading: frame.heading
    )
    options.pointOfInterestFilter = .excludingAll
    if configuration.alwaysUseLightMapAppearance {
      options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }

    for attempt in 0..<snapshotRetryPolicy.maximumAttempts {
      try Task.checkCancellation()
      let snapshotter = MKMapSnapshotter(options: options)
      defer { snapshotter.cancel() }
      do {
        return try await snapshotter.start()
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        guard let delay = snapshotRetryPolicy.delay(afterFailedAttempt: attempt) else {
          Log.ui.error("Failed to render video map frame after retries: \(error.localizedDescription)")
          throw ExportError.videoPreparationFailure
        }
        try await Task.sleep(for: delay)
      }
    }
    throw ExportError.videoPreparationFailure
  }

  private func drawRoute(
    in snapshot: MKMapSnapshotter.Snapshot,
    coordinates: [CLLocationCoordinate2D],
    frame: CinematicRouteFrame,
    driveWidth: CGFloat
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
      path.lineWidth = driveWidth
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      path.stroke()
    }
  }

  private func evenSize(_ size: CGSize) -> CGSize {
    CGSize(width: Int(size.width) / 2 * 2, height: Int(size.height) / 2 * 2)
  }
}

struct VideoExportRenderConfiguration {
  let size: CGSize
  let driveWidth: CGFloat
  let alwaysUseLightMapAppearance: Bool
}

private struct VideoWriterContext {
  let writer: AVAssetWriter
  let receiver: AVAssetWriterInput.PixelBufferReceiver
}

struct VideoSnapshotRetryPolicy {
  let maximumAttempts = 3

  func delay(afterFailedAttempt attempt: Int) -> Duration? {
    guard attempt < maximumAttempts - 1 else { return nil }
    return .milliseconds(250 * (attempt + 1))
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

  static func draw(
    _ image: UIImage,
    into mutableBuffer: borrowing CVMutablePixelBuffer,
    overlay: () -> Void = { }
  ) throws {
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
      context.saveGState()
      context.translateBy(x: 0, y: CGFloat(CVPixelBufferGetHeight(buffer)))
      context.scaleBy(x: 1, y: -1)
      UIGraphicsPushContext(context)
      overlay()
      UIGraphicsPopContext()
      context.restoreGState()
    }
  }
}
