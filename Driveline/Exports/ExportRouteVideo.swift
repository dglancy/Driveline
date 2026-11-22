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

    for range in VideoSnapshotBatchPlanner.ranges(frameCount: frames.count) {
      do {
        try await renderAndAppendBatch(
          frames: frames,
          range: range,
          coordinates: coordinates,
          configuration: configuration,
          writerContext: writerContext
        )
      } catch {
        writer.cancelWriting()
        throw error
      }
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

  private func renderAndAppendBatch(
    frames: [CinematicRouteFrame],
    range: Range<Int>,
    coordinates: [CLLocationCoordinate2D],
    configuration: VideoExportRenderConfiguration,
    writerContext: VideoWriterContext
  ) async throws {
    let firstIndex = range.lowerBound
    guard range.count == VideoSnapshotBatchPlanner.maximumConcurrentSnapshots else {
      let snapshot = try await snapshot(for: frames[firstIndex], configuration: configuration)
      try await append(
        snapshot: snapshot.value,
        frame: frames[firstIndex],
        at: firstIndex,
        coordinates: coordinates,
        configuration: configuration,
        writerContext: writerContext
      )
      return
    }

    let secondIndex = firstIndex + 1
    async let firstSnapshot = snapshot(for: frames[firstIndex], configuration: configuration)
    async let secondSnapshot = snapshot(for: frames[secondIndex], configuration: configuration)

    try await append(
      snapshot: firstSnapshot.value,
      frame: frames[firstIndex],
      at: firstIndex,
      coordinates: coordinates,
      configuration: configuration,
      writerContext: writerContext
    )
    try await append(
      snapshot: secondSnapshot.value,
      frame: frames[secondIndex],
      at: secondIndex,
      coordinates: coordinates,
      configuration: configuration,
      writerContext: writerContext
    )
  }

  private func append(
    snapshot: MKMapSnapshotter.Snapshot,
    frame: CinematicRouteFrame,
    at index: Int,
    coordinates: [CLLocationCoordinate2D],
    configuration: VideoExportRenderConfiguration,
    writerContext: VideoWriterContext
  ) async throws {
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
  ) async throws -> VideoMapSnapshot {
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
        return VideoMapSnapshot(value: try await snapshotter.start())
      } catch is CancellationError {
        throw CancellationError()
      } catch {
        try Task.checkCancellation()
        guard snapshotRetryPolicy.shouldRetry(error),
              let delay = snapshotRetryPolicy.delay(
                afterFailedAttempt: attempt,
                jitter: Double.random(in: -1...1)
              ) else {
          Log.ui.error("Failed to render video map frame: \(error.localizedDescription)")
          throw ExportError.videoPreparationFailure
        }
        Log.ui.info("Retrying a transient video map frame failure: \(error.localizedDescription)")
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
    let routeCoordinates = VideoRouteCoordinateSequence(
      coordinates: coordinates,
      completedSampleIndex: frame.completedSampleIndex,
      endpoint: frame.coordinate
    )
    let visibleBounds = CGRect(origin: .zero, size: snapshot.image.size).insetBy(dx: -20, dy: -20)
    let path = VideoRoutePathBuilder.visiblePath(
      points: routeCoordinates.lazy.map(snapshot.point(for:)),
      within: visibleBounds
    )

    UIColor.systemBlue.setStroke()
    path.lineWidth = driveWidth
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.stroke()
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

private struct VideoMapSnapshot: @unchecked Sendable {
  let value: MKMapSnapshotter.Snapshot
}

struct VideoSnapshotRetryPolicy {
  let maximumAttempts = 4
  private let baseDelayMilliseconds = [500, 1_500, 4_000]
  private let maximumJitterFraction = 0.2

  func delay(afterFailedAttempt attempt: Int, jitter: Double) -> Duration? {
    guard baseDelayMilliseconds.indices.contains(attempt) else { return nil }
    let boundedJitter = Swift.min(Swift.max(jitter, -1), 1)
    let multiplier = 1 + boundedJitter * maximumJitterFraction
    return .milliseconds(Int(Double(baseDelayMilliseconds[attempt]) * multiplier))
  }

  func shouldRetry(_ error: any Error) -> Bool {
    let error = error as NSError
    if isTransient(error) { return true }
    guard let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError else { return false }
    return isTransient(underlyingError)
  }

  private func isTransient(_ error: NSError) -> Bool {
    if error.domain == MKErrorDomain {
      return [
        Int(MKError.Code.loadingThrottled.rawValue),
        Int(MKError.Code.serverFailure.rawValue),
        Int(MKError.Code.unknown.rawValue)
      ].contains(error.code)
    }
    if error.domain == NSURLErrorDomain {
      return [
        NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorResourceUnavailable,
        NSURLErrorCannotLoadFromNetwork,
        NSURLErrorBadServerResponse,
        NSURLErrorDataNotAllowed,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorCallIsActive
      ].contains(error.code)
    }
    return error.domain == "kCFErrorDomainCFNetwork"
      || error.domain.hasPrefix("com.apple.maps.snapshot")
  }
}

enum VideoSnapshotBatchPlanner {
  static let maximumConcurrentSnapshots = 2

  static func ranges(frameCount: Int) -> [Range<Int>] {
    guard frameCount > 0 else { return [] }
    return stride(from: 0, to: frameCount, by: maximumConcurrentSnapshots).map { start in
      start..<Swift.min(start + maximumConcurrentSnapshots, frameCount)
    }
  }
}

enum VideoRoutePathBuilder {

  static func visiblePath<Points: Sequence>(points: Points, within bounds: CGRect) -> UIBezierPath
  where Points.Element == CGPoint {
    let path = UIBezierPath()
    var hasVisiblePoint = false

    for point in points {
      guard point.x.isFinite, point.y.isFinite, bounds.contains(point) else {
        hasVisiblePoint = false
        continue
      }
      if hasVisiblePoint {
        path.addLine(to: point)
      } else {
        path.move(to: point)
        hasVisiblePoint = true
      }
    }
    return path
  }

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

struct VideoRouteCoordinateSequence: Sequence {
  let coordinates: [CLLocationCoordinate2D]
  let completedSampleIndex: Int
  let endpoint: CLLocationCoordinate2D

  func makeIterator() -> Iterator {
    let lastCompletedIndex = coordinates.isEmpty
      ? -1
      : Swift.min(Swift.max(completedSampleIndex, 0), coordinates.count - 1)
    return Iterator(
      coordinates: coordinates,
      lastCompletedIndex: lastCompletedIndex,
      endpoint: endpoint
    )
  }

  struct Iterator: IteratorProtocol {
    let coordinates: [CLLocationCoordinate2D]
    let lastCompletedIndex: Int
    let endpoint: CLLocationCoordinate2D
    var index = 0
    var emittedEndpoint = false

    mutating func next() -> CLLocationCoordinate2D? {
      if index <= lastCompletedIndex {
        defer { index += 1 }
        return coordinates[index]
      }
      guard !emittedEndpoint else { return nil }
      emittedEndpoint = true
      return endpoint
    }
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
    try autoreleasepool {
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
        context.draw(
          cgImage,
          in: CGRect(
            x: 0,
            y: 0,
            width: CVPixelBufferGetWidth(buffer),
            height: CVPixelBufferGetHeight(buffer)
          )
        )
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
}
