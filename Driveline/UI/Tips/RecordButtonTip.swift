//
//  RecordButtonTip.swift
//  Driveline
//
//  Created by Damien Glancy on 16/06/2026.
//

import SwiftUI
import TipKit

struct RecordButtonTip: Tip {
  @Parameter static var isOnboardingPresented: Bool = true
  @Parameter static var hasDrives: Bool = false
  @Parameter static var isRecording: Bool = false

  var rules: [Rule] {
    #Rule(Self.$isOnboardingPresented) { $0 == false }
    #Rule(Self.$hasDrives) { $0 == true }
    #Rule(Self.$isRecording) { $0 == false }
  }

  var title: Text {
    Text("Record a Drive", comment: "TipKit tip title for the home screen record button")
  }
  var message: Text? {
    Text("Tap to start manually tracking a new journey.", comment: "TipKit tip message for the home screen record button")
  }
  var image: Image? {
    Image(systemName: "record.circle")
  }
}
