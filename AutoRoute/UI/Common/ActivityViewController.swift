//
//  ActivityViewController.swift
//  AutoRoute
//
//  Created by Damien Glancy on 01/06/2026.
//

import SwiftUI

struct ActivityViewController: UIViewControllerRepresentable {

  // MARK: - Properties

  let activityItems: [Any]

  // MARK: - UIViewControllerRepresentable

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
