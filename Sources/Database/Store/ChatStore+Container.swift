//
//  ChatStore+Container.swift
//  ChatBotAiPackage
//
//  Where the chat cache lives on disk, and how it recovers from a bad file.
//

import Foundation
import SwiftData
import EkaVoiceToRx

extension ChatStore {
  static let storeURL = URL.applicationSupportDirectory
    .appending(path: "DocAssist", directoryHint: .isDirectory)
    .appending(path: "Chats.store")

  static func makeContainer() -> ModelContainer {
    let schema = Schema(ChatSchemaV1.models + [VoiceConversationModel.self])
    try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)

    /// The Matrix session links used to live in UserDefaults; they now live on `ChatSession`.
    UserDefaults.standard.removeObject(forKey: "DocAssistMatrixSessionIds")

    do {
      return try openContainer(schema: schema)
    } catch {
      /// A cache that cannot be opened is rebuilt; the chats come back from the server.
      print("#ChatStore could not open the store, recreating it: \(error)")
      for suffix in ["", "-shm", "-wal"] {
        try? FileManager.default.removeItem(at: URL(filePath: storeURL.path() + suffix))
      }
      do {
        return try openContainer(schema: schema)
      } catch {
        fatalError("DocAssist chat store unavailable: \(error)")
      }
    }
  }

  private static func openContainer(schema: Schema) throws -> ModelContainer {
    try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: storeURL))
  }
}
