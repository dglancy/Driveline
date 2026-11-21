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
  private let snapshotRetryCount = 3

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
    let renderContext = VideoRenderContext(
      size: evenSize(preferences.exportMapSize),
      coordinates: coordinates,
      driveWidth: preferences.driveWidth
    )
    let alwaysUseLightMapAppearance = preferences.alwaysUseLightMapAppearance
    let writerContext = try makeWriterContext(size: renderContext.size, outputURL: outputURL)
    var snapshotState = try await initialSnapshotState(
      frames: frames,
      context: renderContext,
      alwaysUseLightMapAppearance: alwaysUseLightMapAppearance
    )
    do {
      try writerContext.writer.start()
    } catch {
      throw ExportError.videoEncodingFailure
    }
    writerContext.writer.startSession(atSourceTime: .zero)

    for (index, frame) in frames.enumerated() {
      try await advanceSnapshotsIfNeeded(
        state: &snapshotState,
        frameIndex: index,
        frames: frames,
        context: renderContext,
        alwaysUseLightMapAppearance: alwaysUseLightMapAppearance
      )
      try await append(
        frame: frame,
        at: index,
        snapshots: snapshotState.pair(forFrameIndex: index),
        renderContext: renderContext,
        writerContext: writerContext
      )
    }

    writerContext.receiver.finish()
    await writerContext.writer.finishWriting()
    guard writerContext.writer.status == .completed else { throw ExportError.videoEncodingFailure }
  }

  private func makeWriterContext(size: CGSize, outputURL: URL) throws -> VideoWriterContext {
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

  private func initialSnapshotState(
    frames: [CinematicRouteFrame],
    context: VideoRenderContext,
    alwaysUseLightMapAppearance: Bool
  ) async throws -> VideoSnapshotState {
    let upperIndex = min(VideoSnapshotCadence.frameInterval, frames.count - 1)
    let lowerSnapshot = try await snapshot(
      for: frames[0], size: context.size, alwaysUseLightMapAppearance: alwaysUseLightMapAppearance
    )
    let upperSnapshot = upperIndex == 0 ? lowerSnapshot : try await snapshot(
      for: frames[upperIndex], size: context.size, alwaysUseLightMapAppearance: alwaysUseLightMapAppearance
    )
    return VideoSnapshotState(lowerIndex: 0, upperIndex: upperIndex, lower: lowerSnapshot, upper: upperSnapshot)
  }

  private func advanceSnapshotsIfNeeded(
    state: inout VideoSnapshotState,
    frameIndex: Int,
    frames: [CinematicRouteFrame],
    context: VideoRenderContext,
    alwaysUseLightMapAppearance: Bool
  ) async throws {
    guard frameIndex > state.upperIndex else { return }
    state.lowerIndex = state.upperIndex
    state.lower = state.upper
    state.upperIndex = min(state.lowerIndex + VideoSnapshotCadence.frameInterval, frames.count - 1)
    state.upper = try await snapshot(
      for: frames[state.upperIndex], size: context.size, alwaysUseLightMapAppearance: alwaysUseLightMapAppearance
    )
  }

  private func append(
    frame: CinematicRouteFrame,
    at index: Int,
    snapshots: VideoSnapshotPair,
    renderContext: VideoRenderContext,
    writerContext: VideoWriterContext
  ) async throws {
    guard let pool = writerContext.receiver.pixelBufferPool else {
      writerContext.writer.cancelWriting()
      throw ExportError.videoEncodingFailure
    }
    do {
      let mutableBuffer = try pool.makeMutablePixelBuffer()
      try VideoPixelBufferRenderer.draw(image(for: frame, snapshots: snapshots, context: renderContext), into: mutableBuffer)
      let time = CMTime(value: CMTimeValue(index), timescale: CMTimeScale(CinematicRoutePlan.framesPerSecond))
      try await writerContext.receiver.append(CVReadOnlyPixelBuffer(mutableBuffer), with: time)
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

  private func image(
    for frame: CinematicRouteFrame,
    snapshots: VideoSnapshotPair,
    context: VideoRenderContext
  ) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    return UIGraphicsImageRenderer(size: context.size, format: format).image { _ in
      snapshots.lower.image.draw(in: CGRect(origin: .zero, size: context.size))
      if snapshots.progress > 0 {
        snapshots.upper.image.draw(
          in: CGRect(origin: .zero, size: context.size),
          blendMode: .normal,
          alpha: snapshots.progress
        )
      }
      drawRoute(frame: frame, snapshots: snapshots, context: context)
      VideoVehicleMarkerRenderer.draw(
        at: interpolatedPoint(for: frame.coordinate, snapshots: snapshots)
      )
    }
  }

  private func snapshot(
    for frame: CinematicRouteFrame,
    size: CGSize,
    alwaysUseLightMapAppearance: Bool
  ) async throws -> MKMapSnapshotter.Snapshot {
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
    if alwaysUseLightMapAppearance {
      options.traitCollection = UITraitCollection(userInterfaceStyle: .light)
    }

    for attempt in 0..<snapshotRetryCount {
      do {
        return try await MKMapSnapshotter(options: options).start()
      } catch {
        guard attempt < snapshotRetryCount - 1 else {
          Log.ui.error("Failed to render video map keyframe after retries: \(error.localizedDescription)")
          throw ExportError.videoPreparationFailure
        }
        try await Task.sleep(for: .milliseconds(250 * (attempt + 1)))
      }
    }
    throw ExportError.videoPreparationFailure
  }

  private func drawRoute(
    frame: CinematicRouteFrame,
    snapshots: VideoSnapshotPair,
    context: VideoRenderContext
  ) {
    guard !context.coordinates.isEmpty else { return }
    let lastIndex = min(context.coordinates.count - 1, frame.completedSampleIndex)
    let completedCoordinates = Array(context.coordinates[0...lastIndex]) + [frame.coordinate]
    let points = completedCoordinates.map {
      interpolatedPoint(for: $0, snapshots: snapshots)
    }
    let visibleBounds = CGRect(origin: .zero, size: snapshots.lower.image.size).insetBy(dx: -20, dy: -20)
    let segments = VideoRoutePathBuilder.visibleSegments(points: points, within: visibleBounds)

    UIColor.systemBlue.setStroke()
    for segment in segments {
      let path = UIBezierPath()
      path.move(to: segment[0])
      for point in segment.dropFirst() {
        path.addLine(to: point)
      }
      path.lineWidth = context.driveWidth
      path.lineCapStyle = .round
      path.lineJoinStyle = .round
      path.stroke()
    }
  }

  private func interpolatedPoint(
    for coordinate: CLLocationCoordinate2D,
    snapshots: VideoSnapshotPair
  ) -> CGPoint {
    let lowerPoint = snapshots.lower.point(for: coordinate)
    let upperPoint = snapshots.upper.point(for: coordinate)
    return CGPoint(
      x: lowerPoint.x + ((upperPoint.x - lowerPoint.x) * snapshots.progress),
      y: lowerPoint.y + ((upperPoint.y - lowerPoint.y) * snapshots.progress)
    )
  }

  private func evenSize(_ size: CGSize) -> CGSize {
    CGSize(width: Int(size.width) / 2 * 2, height: Int(size.height) / 2 * 2)
  }
}

private struct VideoRenderContext {
  let size: CGSize
  let coordinates: [CLLocationCoordinate2D]
  let driveWidth: CGFloat
}

private struct VideoWriterContext {
  let writer: AVAssetWriter
  let receiver: AVAssetWriterInput.PixelBufferReceiver
}

private struct VideoSnapshotPair {
  let lower: MKMapSnapshotter.Snapshot
  let upper: MKMapSnapshotter.Snapshot
  let progress: CGFloat
}

private struct VideoSnapshotState {
  var lowerIndex: Int
  var upperIndex: Int
  var lower: MKMapSnapshotter.Snapshot
  var upper: MKMapSnapshotter.Snapshot

  func pair(forFrameIndex frameIndex: Int) -> VideoSnapshotPair {
    let span = max(upperIndex - lowerIndex, 1)
    let progress = CGFloat(frameIndex - lowerIndex) / CGFloat(span)
    return VideoSnapshotPair(lower: lower, upper: upper, progress: progress)
  }
}

enum VideoSnapshotCadence {

  static let framesPerSecond = 6
  static let frameInterval = CinematicRoutePlan.framesPerSecond / framesPerSecond

  static func keyframeCount(forFrameCount frameCount: Int) -> Int {
    guard frameCount > 0 else { return 0 }
    return ((frameCount - 1 + frameInterval - 1) / frameInterval) + 1
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
