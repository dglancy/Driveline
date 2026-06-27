//
//  IPadEmptyStateView.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import SwiftUI

struct IPadEmptyStateView: View {

  var body: some View {
    ContentUnavailableView {
      Label(
        String(localized: "No Drives Yet", comment: "iPad sidebar empty state title when no drives are synced"),
        systemImage: Icons.Widgets.car
      )
    } description: {
      Text(String(localized: "Record drives on your iPhone. They'll appear here automatically via iCloud.", comment: "iPad sidebar empty state description explaining iCloud sync"))
    }
  }
}
