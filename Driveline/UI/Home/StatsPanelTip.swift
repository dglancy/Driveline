//
//  StatsPanelTip.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import SwiftUI
import TipKit

struct StatsPanelTip: Tip {
  @Parameter static var hasDrives: Bool = false

  var rules: [Rule] {
    #Rule(Self.$hasDrives) { $0 == true }
  }

  var title: Text {
    Text("Switch Stats View", comment: "TipKit tip title for the home screen stats panel")
  }
  var message: Text? {
    Text("Tap to toggle between the last 30 days and all time.", comment: "TipKit tip message for the home screen stats panel")
  }
  var image: Image? {
    Image(systemName: "calendar")
  }
}
