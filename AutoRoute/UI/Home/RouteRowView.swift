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
  var isSelected: Bool?

  // MARK: - Body

  var body: some View {
    HStack(spacing: 13) {
      if let isSelected {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 24))
          .foregroundStyle(isSelected ? Color.accentColor : Color(.tertiaryLabel))
          .animation(.easeInOut(duration: 0.15), value: isSelected)
      }
      iconBadge

      VStack(alignment: .leading, spacing: 1) {
        Text(route.name)
          .font(.system(size: 17, weight: .semibold))
          .lineLimit(1)
        Text(dateTimeLabel)
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if let duration = formattedDuration {
        Text(duration)
          .font(.system(size: 13))
          .foregroundStyle(.tertiary)
      }
    }
  }

  // MARK: - Private Views

  private var iconBadge: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 11)
        .fill(.tint.opacity(0.14))
        .frame(width: 38, height: 38)
      Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
        .font(.system(size: 21))
        .foregroundStyle(.tint)
    }
  }

  // MARK: - Computed Properties

  private var dateTimeLabel: String {
    let datePart = route.startedAt.formatted(.dateTime.month(.abbreviated).day())
    let timePart = route.startedAt.formatted(.dateTime.hour().minute())
    return "\(datePart) · \(timePart)"
  }

  private var formattedDuration: String? {
    guard route.endedAt != nil else { return nil }
    return route.activeDurationSeconds.localizedDurationString()
  }
}
