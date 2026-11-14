//
//  ChatStore.swift
//  ChatBotAiPackage
//
//  The single writer for the chat cache. Views read with `@Query` from
//  `ChatStore.container`; every change goes through this actor.
//
//  Split by concern:
//    ChatStore+Container    the database file
//    ChatStore+Sessions     chat lifecycle
//    ChatStore+Messages     sending, streaming, Voice-to-Rx, search
//    ChatStore+Remote       merging server history
//    ChatStore+MatrixLinks  chat <-> Matrix session id
//

import Foundation
import SwiftData

@ModelActor
public actor ChatStore {

  public static let shared = ChatStore(modelContainer: container)

  /// DocAssist's own database. Voice-to-Rx recordings started from a chat live here too.
  public static let container: ModelContainer = makeContainer()

  /// Wipes the cache. Prefer `DocAssistData.clearAll()`, which also removes the tokens.
  public func deleteAll() {
    try? modelContext.delete(model: ChatMessage.self)
    try? modelContext.delete(model: ChatSession.self)
    save()
  }

  // MARK: - Shared helpers for the extensions (actor-isolated, not for callers)

  func session(id: String) -> ChatSession? {
    try? modelContext.fetch(ChatSession.withId(id)).first
  }

  func session(matrixSessionId: String) -> ChatSession? {
    try? modelContext.fetch(ChatSession.withMatrixSessionId(matrixSessionId)).first
  }

  func message(id: String) -> ChatMessage? {
    try? modelContext.fetch(ChatMessage.withId(id)).first
  }

  func messageCount(sessionId: String) -> Int {
    (try? modelContext.fetchCount(ChatMessage.inSession(sessionId))) ?? 0
  }

  func nextSequence(sessionId: String) -> Int {
    ((try? modelContext.fetch(ChatMessage.last(inSession: sessionId)).first?.sequence) ?? 0) + 1
  }

  func save() {
    do {
      try modelContext.save()
    } catch {
      print("#ChatStore save failed: \(error)")
    }
  }
}
