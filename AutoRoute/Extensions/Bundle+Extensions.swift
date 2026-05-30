//
//  Bundle+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 30/05/2026.
//

import Foundation

extension Bundle {
  var appName: String {
    if let displayName = object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
      return displayName
    }

    return object(forInfoDictionaryKey: "CFBundleName") as? String ?? kAppName
  }
}
