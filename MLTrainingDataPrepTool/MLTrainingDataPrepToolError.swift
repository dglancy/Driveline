//
//  MLTrainingDataPrepToolError.swift
//  MLTrainingDataPrepTool
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation

// MARK: - Tool errors

enum MLTrainingDataPrepToolError: Error, LocalizedError, Equatable {
  case inputDirectoryNotFound(String)
  case noGPXFilesFound(String)
  case csvEncodingFailed

  // MARK: - LocalizedError

  var errorDescription: String? {
    switch self {
    case .inputDirectoryNotFound(let path):
      return "The input directory does not exist: \(path)"
    case .noGPXFilesFound(let path):
      return "No .gpx files were found in: \(path)"
    case .csvEncodingFailed:
      return "Failed to encode CSV output as UTF-8."
    }
  }
}
