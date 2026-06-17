//
//  Bundle+Extensions.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import Foundation

extension Bundle {
  var iconFileName: String? {
    guard
      let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
      let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
      let files = primary["CFBundleIconFiles"] as? [String],
      let name = files.last else { return nil }
    return name
  }
}
