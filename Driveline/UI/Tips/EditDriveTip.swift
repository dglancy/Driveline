//
//  EditDriveTip.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import SwiftUI
import TipKit

struct EditDriveTip: Tip {

  // MARK: - Properties

  @Parameter static var isOnboardingPresented: Bool = true

  // MARK: - Rules

  var rules: [Rule] {
    #Rule(Self.$isOnboardingPresented) { $0 == false }
  }

  // MARK: - Computed Properties

  var title: Text {
    Text("Edit Your Drive", comment: "TipKit tip title for the drive detail options button")
  }
  var message: Text? {
    Text("Tap the options button to edit the name and other details.", comment: "TipKit tip message for the drive detail options button")
  }
  var image: Image? {
    Image(systemName: "ellipsis.circle")
  }
}
