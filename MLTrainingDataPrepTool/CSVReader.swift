//
//  CSVReader.swift
//  MLTrainingDataPrepTool
//
//  Created by Damien Glancy on 12/06/2026.
//

import Foundation

// MARK: - CSV reader

enum CSVReader {

  // MARK: - Actions

  static func existingNames(at url: URL) throws -> Set<String> {
    guard FileManager.default.fileExists(atPath: url.path) else {
      return []
    }

    let content = try String(contentsOf: url, encoding: .utf8)
    let rows = parseRows(from: content)
    return Set(rows.dropFirst().compactMap(\.first))
  }

  static func parseRows(from content: String) -> [[String]] {
    var rows: [[String]] = []
    var currentRow: [String] = []
    var currentField = ""
    var insideQuotes = false
    var hasContent = false

    let characters = Array(content)
    var index = 0
    while index < characters.count {
      let character = characters[index]

      if insideQuotes {
        if character == "\"" {
          if index + 1 < characters.count, characters[index + 1] == "\"" {
            currentField.append("\"")
            index += 1
          } else {
            insideQuotes = false
          }
        } else {
          currentField.append(character)
        }
      } else {
        switch character {
        case "\"":
          insideQuotes = true
          hasContent = true
        case ",":
          currentRow.append(currentField)
          currentField = ""
          hasContent = true
        case "\n":
          currentRow.append(currentField)
          rows.append(currentRow)
          currentRow = []
          currentField = ""
          hasContent = false
        case "\r":
          break
        default:
          currentField.append(character)
          hasContent = true
        }
      }

      index += 1
    }

    if hasContent || !currentField.isEmpty || !currentRow.isEmpty {
      currentRow.append(currentField)
      rows.append(currentRow)
    }

    return rows
  }
}
