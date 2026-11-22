//
//  VideoPixelBufferRendererTests.swift
//  DrivelineTests
//
//  Created by Damien Glancy on 21/11/2026.
//

@testable import Driveline
import CoreVideo
import Testing
import UIKit

@Suite("VideoPixelBufferRenderer")
@MainActor
struct VideoPixelBufferRendererTests {

  @Test
  func snapshotRetryPolicyUsesBoundedBackoff() {
    let policy = VideoSnapshotRetryPolicy()

    #expect(policy.maximumAttempts == 3)
    #expect(policy.delay(afterFailedAttempt: 0) == .milliseconds(250))
    #expect(policy.delay(afterFailedAttempt: 1) == .milliseconds(500))
    #expect(policy.delay(afterFailedAttempt: 2) == nil)
  }

  @Test
  func routePathBreaksAroundOffscreenAndInvalidProjectedPoints() {
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    let points = [
      CGPoint(x: 10, y: 10),
      CGPoint(x: 20, y: 20),
      CGPoint(x: -1_000, y: 50),
      CGPoint(x: 40, y: 40),
      CGPoint(x: 50, y: 50),
      CGPoint(x: CGFloat.infinity, y: 60),
      CGPoint(x: 70, y: 70)
    ]

    let segments = VideoRoutePathBuilder.visibleSegments(points: points, within: bounds)

    #expect(segments == [
      [CGPoint(x: 10, y: 10), CGPoint(x: 20, y: 20)],
      [CGPoint(x: 40, y: 40), CGPoint(x: 50, y: 50)]
    ])
  }

  @Test
  func routeCoordinateSequenceStreamsCompletedPrefixAndCurrentEndpoint() {
    let coordinates = [
      CLLocationCoordinate2D(latitude: 53.0, longitude: -6.0),
      CLLocationCoordinate2D(latitude: 53.1, longitude: -6.1),
      CLLocationCoordinate2D(latitude: 53.2, longitude: -6.2)
    ]
    let endpoint = CLLocationCoordinate2D(latitude: 53.15, longitude: -6.15)

    let result = Array(VideoRouteCoordinateSequence(
      coordinates: coordinates,
      completedSampleIndex: 1,
      endpoint: endpoint
    ))

    #expect(result.map(\.latitude) == [53.0, 53.1, 53.15])
    #expect(result.map(\.longitude) == [-6.0, -6.1, -6.15])
  }

  @Test
  func visiblePathPreservesBreaksBetweenOffscreenPoints() {
    let bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
    let points = [
      CGPoint(x: 10, y: 10),
      CGPoint(x: 20, y: 20),
      CGPoint(x: -1_000, y: 50),
      CGPoint(x: 40, y: 40),
      CGPoint(x: 50, y: 50)
    ]

    let path = VideoRoutePathBuilder.visiblePath(points: points, within: bounds)

    #expect(path.cgPath.boundingBoxOfPath == CGRect(x: 10, y: 10, width: 40, height: 40))
    #expect(path.currentPoint == CGPoint(x: 50, y: 50))
  }

  @Test
  func vehicleMarkerIsDirectionNeutralDotCenteredOnCoordinate() {
    let center = CGPoint(x: 42, y: 24)
    let rect = VideoVehicleMarkerRenderer.markerRect(centeredAt: center)

    #expect(rect.midX == center.x)
    #expect(rect.midY == center.y)
    #expect(rect.width == rect.height)
  }

  @Test
  func rendererWritesBGRAChannelsInVideoBufferOrder() throws {
    let buffer = try makeBuffer(width: 2, height: 2)
    let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
      UIColor(red: 1, green: 0, blue: 0, alpha: 1).setFill()
      context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    }

    try VideoPixelBufferRenderer.draw(image, into: buffer)

    try buffer.withUnsafeBuffer { pixelBuffer in
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
      let bytes = try #require(CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self))
      #expect(bytes[0] == 0)
      #expect(bytes[1] == 0)
      #expect(bytes[2] == 255)
      #expect(bytes[3] == 255)
    }
  }

  @Test
  func rendererKeepsTopAndBottomRowsInDisplayOrder() throws {
    let buffer = try makeBuffer(width: 2, height: 2)
    let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
      UIColor.red.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 2, height: 1))
      UIColor.blue.setFill()
      context.fill(CGRect(x: 0, y: 1, width: 2, height: 1))
    }

    try VideoPixelBufferRenderer.draw(image, into: buffer)

    try buffer.withUnsafeBuffer { pixelBuffer in
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
      let bytes = try #require(CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self))
      let bottomRowOffset = CVPixelBufferGetBytesPerRow(pixelBuffer)
      #expect(bytes[2] > 200)
      #expect(bytes[0] < 30)
      #expect(bytes[bottomRowOffset] > 200)
      #expect(bytes[bottomRowOffset + 2] < 30)
    }
  }

  @Test
  func rendererDrawsOverlayDirectlyIntoTopOfPixelBuffer() throws {
    let buffer = try makeBuffer(width: 4, height: 4)
    let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
    }

    try VideoPixelBufferRenderer.draw(image, into: buffer) {
      UIColor.red.setFill()
      UIBezierPath(rect: CGRect(x: 0, y: 0, width: 4, height: 1)).fill()
    }

    try buffer.withUnsafeBuffer { pixelBuffer in
      CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
      defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
      let bytes = try #require(CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self))
      let bottomRowOffset = CVPixelBufferGetBytesPerRow(pixelBuffer) * 3
      #expect(bytes[2] > 200)
      #expect(bytes[0] < 30)
      #expect(bytes[bottomRowOffset] > 200)
      #expect(bytes[bottomRowOffset + 2] > 200)
    }
  }

  private func makeBuffer(width: Int, height: Int) throws -> CVMutablePixelBuffer {
    let attributes = CVPixelBufferAttributes(rawAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: width,
      kCVPixelBufferHeightKey as String: height
    ])
    return try CVMutablePixelBuffer(try #require(CVPixelBufferCreationAttributes(attributes)))
  }
}
