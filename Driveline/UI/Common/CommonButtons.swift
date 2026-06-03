//
//  CommonButtons.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

extension Button where Label == Text {

  static func cancel(action: @escaping () -> Void = {}) -> Button<Text> {
    Button(String(localized: "Cancel", comment: "Cancel or dismiss"), role: .cancel, action: action)
  }

  static func delete(action: @escaping () -> Void) -> Button<Text> {
    Button(String(localized: "Delete", comment: "Destructive delete"), role: .destructive, action: action)
  }

  static func save(action: @escaping () -> Void) -> Button<Text> {
    Button(String(localized: "Save", comment: "Save changes"), action: action)
  }
}
