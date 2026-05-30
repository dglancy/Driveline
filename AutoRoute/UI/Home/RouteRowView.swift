//
//  RouteRowView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI

struct RouteRowView: View {

  // MARK: - Properties

  let route: Route

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(route.name)
        .font(.body)
        .fontWeight(.medium)

      HStack(spacing: 6) {
        Text(route.startedAt, style: .time)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        if let duration = formattedDuration {
          Text("·")
            .foregroundStyle(.secondary)
          Text(duration)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      if let placeName = route.startPlaceName {
        Text(placeName)
          .font(.caption)
          .foregroundStyle(.tertiary)
          .lineLimit(1)
      }
    }
    .padding(.vertical, 2)
  }

  // MARK: - Computed Properties

  private var formattedDuration: String? {
    guard route.endedAt != nil else { return nil }
    let duration = route.durationSeconds
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
    return formatter.string(from: duration)
  }
}
