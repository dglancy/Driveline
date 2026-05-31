//
//  ModelContext+Extensions.swift
//  AutoRoute
//
//  Created by Damien Glancy on 31/05/2026.
//

import SwiftData

extension ModelContext {

  func safeSave(onSuccess: (() -> Void)? = nil, onFailure: (Error) -> Void) {
    do {
      try save()
      onSuccess?()
    } catch {
      onFailure(error)
    }
  }
}
