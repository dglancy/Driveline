//
//  DriveRowView.swift
//  Driveline
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI

struct DriveRowView: View {

  // MARK: - Types

  enum Style {
    case list(isSelected: Bool? = nil)
    case card(index: Int)
  }

  // MARK: - Properties

  let display: DriveRowDisplay
  var style: Style = .list()

  // MARK: - Body

  var body: some View {
    switch style {
    case .list(let isSelected):
      listBody(isSelected: isSelected)
    case .card(let index):
      cardBody(index: index)
    }
  }

  // MARK: - Private Views

  @ViewBuilder
  private func listBody(isSelected: Bool?) -> some View {
    HStack(spacing: 13) {
      if let isSelected {
        Image(systemName: isSelected ? Icons.selected : Icons.deselected)
          .font(.title2)
          .foregroundStyle(isSelected ? Color.accentColor : Color(.tertiaryLabel))
          .animation(.easeInOut(duration: 0.15), value: isSelected)
          .accessibilityHidden(true)
      }
      driveBadge
      textContent(nameFont: .body.weight(.semibold), dateFont: .subheadline)
      statsContent(distanceFont: .callout, durationFont: .footnote)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(ListFormatter.localizedString(byJoining: [display.name, display.formattedDistance, display.dateTimeLabel]))
    .accessibilityAddTraits(isSelected == true ? .isSelected : [])
  }

  @ViewBuilder
  private func cardBody(index: Int) -> some View {
    HStack(spacing: 13) {
      indexBadge(index: index)
      textContent(nameFont: .callout.weight(.semibold), dateFont: .footnote)
      statsContent(distanceFont: .callout.weight(.medium), durationFont: .caption)
    }
    .padding(.horizontal, 15)
    .padding(.vertical, 13)
    .cardBackground()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(index). \(ListFormatter.localizedString(byJoining: [display.name, display.formattedDistance, display.dateTimeLabel]))")
  }

  private var driveBadge: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 11)
        .fill(.tint.opacity(0.14))
        .frame(width: 38, height: 38)
      Image(systemName: display.iconName)
        .font(.title3)
        .foregroundStyle(.tint)
        .dynamicTypeSize(.xSmall ... .large)
    }
  }

  private func indexBadge(index: Int) -> some View {
    ZStack {
      Circle()
        .fill(.tint)
        .frame(width: 26, height: 26)
      Text("\(index)")
        .font(.subheadline.weight(.bold))
        .foregroundStyle(.white)
    }
  }

  private func textContent(nameFont: Font, dateFont: Font) -> some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(display.name)
        .font(nameFont)
        .lineLimit(1)
        .dynamicTypeSize(.xSmall ... .accessibility1)
      Text(display.dateTimeLabel)
        .font(dateFont)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .dynamicTypeSize(.xSmall ... .accessibility1)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func statsContent(distanceFont: Font, durationFont: Font) -> some View {
    VStack(alignment: .trailing, spacing: 1) {
      Text(display.formattedDistance)
        .font(distanceFont)
        .dynamicTypeSize(.xSmall ... .accessibility1)
      if let duration = display.formattedDuration {
        Text(duration)
          .font(durationFont)
          .foregroundStyle(.tertiary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
    }
  }
}
