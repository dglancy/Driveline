//
//  DriveAnnotations.swift
//  Driveline
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftUI

struct DriveStartAnnotation: View {

  // MARK: - Body

  var body: some View {
    Circle()
      .fill(Color.green)
      .frame(width: 14, height: 14)
      .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2.5))
      .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
      .accessibilityHidden(true)
  }
}

struct DriveEndAnnotation: View {

  // MARK: - Body

  var body: some View {
    Image(systemName: Icons.Drive.finishFlagCircle)
      .font(.title)
      .foregroundStyle(.red, Color(.systemBackground))
      .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
      .accessibilityHidden(true)
  }
}
