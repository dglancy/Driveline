//
//  DriveViewerPlaceholderView.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import SwiftUI

struct DriveViewerPlaceholderView: View {

  var body: some View {
    ContentUnavailableView(
      String(localized: "Select a Drive", comment: "iPad placeholder when no drive is selected"),
      systemImage: Icons.Widgets.car
    )
  }
}
