//
//  ActivityView.swift
//  Driveline
//
//  Created by Damien Glancy on 13/06/2026.
//

import SwiftUI
import UIKit

struct ActivityView: UIViewControllerRepresentable {

  // MARK: - Properties

  let activityItems: [Any]

  // MARK: - UIViewControllerRepresentable

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
