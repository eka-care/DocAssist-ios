//
//  WebSocketLogger.swift
//  DocAssist-ios
//
//  Created by Brunda B on 25/03/26.
//

import SwiftUI

struct WSLogEntry: Identifiable {
  let id = UUID()
  let timestamp: Date
  let direction: Direction
  let message: String

  enum Direction: String {
    case sent = "SENT"
    case received = "RECV"
    case info = "INFO"
  }

  var formattedTime: String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f.string(from: timestamp)
  }
}

@Observable @MainActor
final class WebSocketLogger {
  static let shared = WebSocketLogger()
  private init() {}

  var logs: [WSLogEntry] = []

  func logSent(_ message: String) {
    let entry = WSLogEntry(timestamp: Date(), direction: .sent, message: message)
    logs.append(entry)
  }

  func logReceived(_ message: String) {
    let entry = WSLogEntry(timestamp: Date(), direction: .received, message: message)
    logs.append(entry)
  }

  func logInfo(_ message: String) {
    let entry = WSLogEntry(timestamp: Date(), direction: .info, message: message)
    logs.append(entry)
  }

  func clear() {
    logs.removeAll()
  }
}
