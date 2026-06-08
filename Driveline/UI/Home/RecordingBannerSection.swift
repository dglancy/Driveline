//
//  RecordingBannerSection.swift
//  Driveline
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

struct RecordingBannerSection: View {

  // MARK: - Properties
  
  let onTap: () -> Void
  
  // MARK: - Body
  
  var body: some View {
    Section {
      Button(action: onTap) {
        HStack(spacing: 12) {
          PulsingDot(color: .red, size: 12)
          VStack(alignment: .leading, spacing: 1) {
            Text("Recording drive…")
              .font(.callout.weight(.semibold))
              .foregroundStyle(Color(.label))
            Text("Tap to view")
              .font(.footnote)
              .foregroundStyle(Color(.secondaryLabel))
            
          }
          Spacer()
          Image(systemName: Icons.Navigation.chevronRight)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color(.tertiaryLabel))
            .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
      }
      .buttonStyle(.plain)
      .listRowBackground(Color.red.opacity(0.08))
    }
    .listSectionSeparator(.hidden)
  }
}
