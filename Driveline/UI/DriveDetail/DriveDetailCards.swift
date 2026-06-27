//
//  DriveDetailCards.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import CoreLocation
import SwiftUI

// MARK: - DriveHeaderCard

struct DriveHeaderCard: View {

  let presenter: DriveDetailPresenter

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(presenter.name)
        .font(.title.weight(.bold))
        .foregroundStyle(Color(.label))
        .lineLimit(2)
        .minimumScaleFactor(0.1)
        .dynamicTypeSize(.xSmall ... .accessibility1)
      Text(presenter.dateString)
        .font(.callout)
        .foregroundStyle(.secondary)
        .dynamicTypeSize(.xSmall ... .accessibility1)
    }
  }
}

// MARK: - DriveStatTilesRow

struct DriveStatTilesRow: View {

  let drive: Drive

  var body: some View {
    let stats = DriveStatsPresenter(drive: drive)
    HStack(spacing: 10) {
      DriveStatTile(
        icon: "ruler",
        label: String(localized: "Distance", comment: "Stat tile label"),
        value: stats.distanceValue,
        unit: stats.distanceUnit
      )
      DriveStatTile(
        icon: "clock",
        label: String(localized: "Duration", comment: "Stat tile label"),
        value: stats.durationValue,
        unit: stats.durationUnit
      )
      DriveStatTile(
        icon: "speedometer",
        label: String(localized: "Avg Speed", comment: "Stat tile label"),
        value: stats.avgSpeedValue,
        unit: stats.avgSpeedUnit
      )
    }
  }
}

// MARK: - DriveEndpointsCard

struct DriveEndpointsCard: View {

  let presenter: DriveDetailPresenter

  var body: some View {
    VStack(spacing: 0) {
      IconRow(
        title: presenter.startPlace ?? String(localized: "Unknown", comment: "Unknown place name"),
        subtitle: String(localized: "Departure", comment: "Endpoint row subtitle"),
        trailing: presenter.departureTime
      ) {
        Circle()
          .fill(Color.green)
          .frame(width: 13, height: 13)
          .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
          .shadow(color: .black.opacity(0.15), radius: 1)
      }

      Divider().padding(.leading, 52)

      IconRow(
        title: presenter.endPlace ?? String(localized: "Unknown", comment: "Unknown place name"),
        subtitle: String(localized: "Arrival", comment: "Endpoint row subtitle"),
        trailing: presenter.arrivalTime
      ) {
        Image(systemName: Icons.Drive.finishFlag)
          .font(.body.weight(.medium))
          .foregroundStyle(.red)
          .dynamicTypeSize(.xSmall ... .xxxLarge)
      }
    }
    .cardBackground(cornerRadius: 16)
  }
}

// MARK: - DriveDetailWeatherCard

struct DriveDetailWeatherCard: View {

  let presenter: DriveDetailPresenter
  let onLoadAttribution: () -> Void

  var body: some View {
    if presenter.hasWeather {
      VStack(spacing: 0) {
        if let symbol = presenter.startWeatherSymbol,
           let description = presenter.startWeatherDescription {
          IconRow(
            title: description,
            subtitle: String(localized: "At Departure", comment: "Weather row subtitle"),
            trailing: presenter.startWeatherTemperature
          ) {
            Image(systemName: symbol)
              .symbolRenderingMode(.multicolor)
              .font(.callout)
              .frame(width: 24)
              .dynamicTypeSize(.xSmall ... .accessibility1)
          }
        }

        if let symbol = presenter.endWeatherSymbol,
           let description = presenter.endWeatherDescription {
          Divider().padding(.leading, 52)
          IconRow(
            title: description,
            subtitle: String(localized: "At Arrival", comment: "Weather row subtitle"),
            trailing: presenter.endWeatherTemperature
          ) {
            Image(systemName: symbol)
              .symbolRenderingMode(.multicolor)
              .font(.callout)
              .frame(width: 24)
              .dynamicTypeSize(.xSmall ... .accessibility1)
          }
        }
      }
      .cardBackground(cornerRadius: 16)
      .task { onLoadAttribution() }
    }
  }
}

// MARK: - DriveDetailMetadataCard

struct DriveDetailMetadataCard: View {

  let presenter: DriveDetailPresenter
  let maxSpeedMPS: CLLocationSpeed
  let positionCount: Int

  var body: some View {
    VStack(spacing: 0) {
      if presenter.hasCategory {
        IconRow(title: String(localized: "Category", comment: "Metadata row"), trailing: presenter.categoryDisplayName) {
          Image(systemName: Icons.Stats.category)
            .font(.callout)
            .foregroundStyle(.secondary)
            .dynamicTypeSize(.xSmall ... .accessibility1)
        }

        Divider().padding(.leading, 52)
      }

      IconRow(title: String(localized: "Top Speed", comment: "Metadata row"), trailing: presenter.topSpeed(maxSpeedMPS: maxSpeedMPS)) {
        Image(systemName: Icons.Stats.speed)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }

      Divider().padding(.leading, 52)

      IconRow(title: String(localized: "Track Points", comment: "Metadata row"), trailing: presenter.trackPoints(count: positionCount)) {
        Image(systemName: Icons.Stats.location)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }

      Divider().padding(.leading, 52)

      IconRow(title: String(localized: "Started by", comment: "Metadata row"), trailing: presenter.triggerDisplayName) {
        Image(systemName: Icons.Stats.gpsSignal)
          .font(.callout)
          .foregroundStyle(.secondary)
          .dynamicTypeSize(.xSmall ... .accessibility1)
      }
    }
    .cardBackground(cornerRadius: 16)
  }
}

// MARK: - ShareDriveButton

struct ShareDriveButton: View {

  let state: DriveDetailState

  var body: some View {
    Menu {
      Button {
        Task { await state.share(.gpx) }
      } label: {
        Label(String(localized: "Share as GPX", comment: "Share drive as GPX"), systemImage: Icons.Options.gpxFile)
      }
      Button {
        Task { await state.share(.png) }
      } label: {
        Label(String(localized: "Share as PNG", comment: "Share drive as PNG"), systemImage: Icons.Options.pngImage)
      }
    } label: {
      Label(String(localized: "Share Drive", comment: "Share button"), systemImage: Icons.Options.sharing)
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .overlay(alignment: .trailing) {
          if state.isPreparingExport {
            ProgressView().padding(.trailing, 16)
          }
        }
    }
    .disabled(!state.canExport || state.isPreparingExport)
    .cardBackground(cornerRadius: 16)
  }
}

// MARK: - WeatherAttributionFooter

struct WeatherAttributionFooter: View {

  let state: DriveDetailState

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    if let legalURL = state.weatherAttributionLegalURL,
       let lightMarkURL = state.weatherAttributionLightMarkURL,
       let darkMarkURL = state.weatherAttributionDarkMarkURL {
      VStack(spacing: 4) {
        Link(destination: legalURL) {
          AsyncImage(url: colorScheme == .dark ? darkMarkURL : lightMarkURL) { image in
            image.resizable().scaledToFit()
          } placeholder: {
            EmptyView()
          }
          .frame(height: 14)
        }
        Link(String(localized: "Weather data provided by Apple Weather", comment: "Weather attribution footer link"), destination: legalURL)
          .font(.caption2)
          .foregroundStyle(Color(.secondaryLabel))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    }
  }
}
