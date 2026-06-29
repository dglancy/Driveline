//
//  DriveInfoPanel.swift
//  Driveline
//
//  Created by Damien Glancy on 27/06/2026.
//

import SwiftUI

struct DriveInfoPanel: View {

  // MARK: - Properties

  let state: DriveDetailState

  // MARK: - Body

  var body: some View {
    let presenter = DriveDetailPresenter(drive: state.drive)
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        DriveHeaderCard(presenter: presenter)
        DriveStatTilesRow(drive: state.drive)
        DriveEndpointsCard(presenter: presenter)
        DriveDetailWeatherCard(presenter: presenter) { state.loadWeatherAttribution() }
        DriveDetailMetadataCard(presenter: presenter, maxSpeedMPS: state.maxSpeedMetresPerSecond, positionCount: state.positionCount)
        ShareDriveButton(state: state)
        Spacer()
        WeatherAttributionFooter(state: state)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 24)
    }
    .padding(.top, 20)
    .contentMargins(.top, 0, for: .scrollContent)
  }
}
