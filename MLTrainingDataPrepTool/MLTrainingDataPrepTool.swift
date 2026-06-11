//
//  MLTrainingDataPrepTool.swift
//  MLTrainingDataPrepTool
//
//  Created by Damien Glancy on 11/06/2026.
//

import ArgumentParser
import Foundation

// MARK: - ML training data prep tool

@main
struct MLTrainingDataPrepTool: ParsableCommand {

  // MARK: - Configuration

  static let configuration = CommandConfiguration(
    commandName: "ml-training-data-prep",
    abstract: "Builds a CSV training dataset from exported GPX drive files."
  )

  // MARK: - Arguments

  @Argument(help: "Directory containing .gpx drive files.")
  var inputDirectory: String

  @Argument(help: "Path to the CSV file to create or append to.")
  var outputCSV: String

  // MARK: - Actions

  func run() throws {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: inputDirectory, isDirectory: &isDirectory), isDirectory.boolValue else {
      throw MLTrainingDataPrepToolError.inputDirectoryNotFound(inputDirectory)
    }

    let inputURL = URL(fileURLWithPath: inputDirectory)
    let gpxFiles = try fileManager.contentsOfDirectory(at: inputURL, includingPropertiesForKeys: nil)
      .filter { $0.pathExtension.lowercased() == "gpx" }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }

    guard !gpxFiles.isEmpty else {
      throw MLTrainingDataPrepToolError.noGPXFilesFound(inputDirectory)
    }

    var records: [GPXDriveStatistics] = []
    for fileURL in gpxFiles {
      do {
        let data = try Data(contentsOf: fileURL)
        let statistics = try GPXStatisticsParser().parse(data: data)
        records.append(statistics)
      } catch {
        let message = "Skipping \(fileURL.lastPathComponent): \(error.localizedDescription)\n"
        FileHandle.standardError.write(Data(message.utf8))
      }
    }

    let outputURL = URL(fileURLWithPath: outputCSV)
    try CSVWriter.append(records, to: outputURL)
  }
}
