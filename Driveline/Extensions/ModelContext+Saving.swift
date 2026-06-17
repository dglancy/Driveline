//
//  ModelContext+Saving.swift
//  Driveline
//
//  Created by Damien Glancy on 17/06/2026.
//

import Foundation
import SwiftData

extension ModelContext {
  
  // MARK: - Actions
  
  @discardableResult
  nonisolated func saveChanges(_ operation: String? = nil) -> Bool {
    guard hasChanges else { return true }
    do {
      try save()
      return true
    } catch {
      let suffix = operation.map { " during \($0)" } ?? ""
      Log.data.error("Failed to save model context\(suffix): \(error.localizedDescription)")
      return false
    }
  }
}
