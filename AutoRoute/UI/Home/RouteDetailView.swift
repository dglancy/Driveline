//
//  RouteDetailView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI

struct RouteDetailView: View {

  // MARK: - Properties

  let route: Route

  // MARK: - Body

  var body: some View {
    Text(route.name)
      .font(.title)
      .fontWeight(.semibold)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle(route.name)
      .navigationBarTitleDisplayMode(.inline)
  }
}
