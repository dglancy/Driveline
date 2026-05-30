//
//  ContentView.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext

  var body: some View {

  }
}

#Preview {
  ContentView()
    .modelContainer(for: Route.self, inMemory: true)
}
