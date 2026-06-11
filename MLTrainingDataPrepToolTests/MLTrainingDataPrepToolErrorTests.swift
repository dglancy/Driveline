//
//  MLTrainingDataPrepToolErrorTests.swift
//  MLTrainingDataPrepToolTests
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation
import Testing

@Suite("MLTrainingDataPrepToolError")
struct MLTrainingDataPrepToolErrorTests {

  // MARK: - Error descriptions

  @Test
  func inputDirectoryNotFoundDescriptionContainsPath() {
    let error = MLTrainingDataPrepToolError.inputDirectoryNotFound("/tmp/missing")

    #expect(error.errorDescription?.contains("/tmp/missing") == true)
  }

  @Test
  func noGPXFilesFoundDescriptionContainsPath() {
    let error = MLTrainingDataPrepToolError.noGPXFilesFound("/tmp/empty")

    #expect(error.errorDescription?.contains("/tmp/empty") == true)
  }

  @Test
  func csvEncodingFailedDescriptionIsNotEmpty() {
    let error = MLTrainingDataPrepToolError.csvEncodingFailed

    #expect(error.errorDescription?.isEmpty == false)
  }
}
