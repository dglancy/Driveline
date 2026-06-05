//
//  DriveStatTile.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct DriveStatTile: View {

  // MARK: - Properties

  let icon: String
  let label: String
  let value: String
  let unit: String

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.caption.weight(.medium))
          .foregroundStyle(.tint)
          .dynamicTypeSize(.xSmall ... .xxLarge)
        Text(label)
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .large)
      }

      Text(value)
        .font(.title2.weight(.semibold))
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .dynamicTypeSize(.xSmall ... .large)

      Text(unit)
        .font(.caption)
        .foregroundStyle(.secondary)
        .dynamicTypeSize(.xSmall ... .large)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .cardBackground()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(Text("\(label): \(value) \(unit)"))
  }
}
