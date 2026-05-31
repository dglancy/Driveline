//
//  EditRouteViewModel.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class EditRouteViewModel {

  // MARK: - Properties

  var routeName: String
  var startPlaceName: String
  var endPlaceName: String

  var isSaveDisabled: Bool { routeName.trimmingCharacters(in: .whitespaces).isEmpty }

  @ObservationIgnored private let route: Route

  // MARK: - Lifecycle

  init(route: Route) {
    self.route = route
    self.routeName = route.name
    self.startPlaceName = route.startPlaceName ?? ""
    self.endPlaceName = route.endPlaceName ?? ""
  }

  // MARK: - Actions

  func save() {
    let trimmedName = routeName.trimmingCharacters(in: .whitespaces)
    if !trimmedName.isEmpty {
      route.name = trimmedName
    }
    let trimmedStart = startPlaceName.trimmingCharacters(in: .whitespaces)
    route.startPlaceName = trimmedStart.isEmpty ? nil : trimmedStart
    let trimmedEnd = endPlaceName.trimmingCharacters(in: .whitespaces)
    route.endPlaceName = trimmedEnd.isEmpty ? nil : trimmedEnd
  }
}
