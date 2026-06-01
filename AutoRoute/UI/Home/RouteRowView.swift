//
//  RouteRowView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI

struct RouteRowView: View {

  // MARK: - Properties

  let display: HomeViewModel.RouteRowDisplay
  var isSelected: Bool?

  // MARK: - Body

  var body: some View {
    HStack(spacing: 13) {
      if let isSelected {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.title2)
          .foregroundStyle(isSelected ? Color.accentColor : Color(.tertiaryLabel))
          .animation(.easeInOut(duration: 0.15), value: isSelected)
          .accessibilityHidden(true)
      }
      iconBadge

      VStack(alignment: .leading, spacing: 1) {
        Text(display.name)
          .font(.body.weight(.semibold))
          .lineLimit(1)
        Text(display.dateTimeLabel)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(alignment: .trailing) {
        Text(display.formattedDistance)
          .font(.callout)
          .foregroundStyle(.primary)
        if let duration = display.formattedDuration {
          Text(duration)
            .font(.footnote)
            .foregroundStyle(.tertiary)
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(display.name), \(display.formattedDistance), \(display.dateTimeLabel)")
    .accessibilityAddTraits(isSelected == true ? .isSelected : [])
  }

  // MARK: - Private Views

  private var iconBadge: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 11)
        .fill(.tint.opacity(0.14))
        .frame(width: 38, height: 38)
      Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
        .font(.title3)
        .foregroundStyle(.tint)
    }
  }
}
