//
//  WebSocketLogView.swift
//  DocAssist-ios
//
//  Created by Brunda B on 25/03/26.
//

import SwiftUI

struct WebSocketLogView: View {
  let logger = WebSocketLogger.shared
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      List {
        if logger.logs.isEmpty {
          ContentUnavailableView(
            "No Logs Yet",
            systemImage: "network.slash",
            description: Text("WebSocket messages will appear here as they are sent and received.")
          )
        } else {
          ForEach(logger.logs) { entry in
            VStack(alignment: .leading, spacing: 4) {
              HStack {
                Text(entry.direction.rawValue)
                  .font(.system(size: 11, weight: .bold, design: .monospaced))
                  .foregroundStyle(colorForDirection(entry.direction))
                  .padding(.horizontal, 6)
                  .padding(.vertical, 2)
                  .background(colorForDirection(entry.direction).opacity(0.15))
                  .cornerRadius(4)

                Text(entry.formattedTime)
                  .font(.system(size: 11, design: .monospaced))
                  .foregroundStyle(.secondary)

                Spacer()
              }

              Text(prettyJSON(entry.message))
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .lineLimit(nil)
            }
            .padding(.vertical, 4)
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle("WebSocket Logs")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Close") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button(role: .destructive) {
              logger.clear()
            } label: {
              Label("Clear Logs", systemImage: "trash")
            }
            Button {
              copyAllLogs()
            } label: {
              Label("Copy All", systemImage: "doc.on.doc")
            }
            ShareLink(item: allLogsText()) {
              Label("Share Logs", systemImage: "square.and.arrow.up")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    }
  }

  private func colorForDirection(_ direction: WSLogEntry.Direction) -> Color {
    switch direction {
    case .sent: return .blue
    case .received: return .green
    case .info: return .orange
    }
  }

  private func prettyJSON(_ string: String) -> String {
    guard let data = string.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data),
          let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
          let result = String(data: pretty, encoding: .utf8) else {
      return string
    }
    return result
  }

  private func allLogsText() -> String {
    logger.logs.map { entry in
      "[\(entry.formattedTime)] [\(entry.direction.rawValue)] \(entry.message)"
    }.joined(separator: "\n\n")
  }

  private func copyAllLogs() {
    UIPasteboard.general.string = allLogsText()
  }
}
