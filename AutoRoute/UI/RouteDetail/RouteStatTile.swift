//
//  RouteStatTile.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct RouteStatTile: View {

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
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.tint)
        Text(label)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(.secondary)
      }

      Text(value)
        .font(.system(size: 24, weight: .semibold))
        .foregroundStyle(.primary)
        .minimumScaleFactor(0.7)
        .lineLimit(1)

      Text(unit)
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
  }
}
