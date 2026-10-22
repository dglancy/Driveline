//
//  ResizableLayoutTests.swift
//  Driveline
//
//  Created by Damien Glancy on 22/10/2026.
//

import SwiftUI
import Testing
import UIKit
@testable import Driveline

@MainActor
struct ResizableLayoutTests {

  // MARK: - Tests

  @Test
  func statsPanelStacksInNarrowWindowAndReturnsToWideLayout() {
    let panel = HomeStatsPanelView(
      driveCount: 100,
      distanceValue: "10,000",
      distanceUnit: "km",
      scopeLabel: "A long reporting period that needs multiple lines in a narrow window",
      onTap: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    let host = UIHostingController(rootView: panel)
    let wide = host.sizeThatFits(in: CGSize(width: 800, height: 10_000))
    let narrow = host.sizeThatFits(in: CGSize(width: 320, height: 10_000))
    let wideAgain = host.sizeThatFits(in: CGSize(width: 800, height: 10_000))

    #expect(narrow.height > wide.height + 80)
    #expect(narrow.width <= 320 + 1 / host.traitCollection.displayScale)
    #expect(abs(wideAgain.height - wide.height) < 1)
  }

  @Test
  func selectionToolbarFitsNarrowWindowWithLargeText() {
    let toolbar = SelectionToolbar(
      canMerge: true,
      canDelete: true,
      selectionCountText: "2 selected",
      onMerge: {},
      onDelete: {}
    )
    .environment(\.dynamicTypeSize, .accessibility1)
    let host = UIHostingController(rootView: toolbar)
    let size = host.sizeThatFits(in: CGSize(width: 320, height: 10_000))

    #expect(size.width <= 320)
    #expect(size.height > 20)
    #expect(size.height < 320)
  }
}
