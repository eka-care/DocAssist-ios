//
//  ChatStore+Remote.swift
//  ChatBotAiPackage
//
//  Writes server history into the cache. The device is the source of truth:
//  server data only fills in chats and messages the device does not have.
//

import Foundation
import SwiftData

extension ChatStore {

  /// Adds server chats the device does not have and names placeholder chats.
  /// Hidden (deleted) chats stay hidden.
  func mergeRemoteSessions(_ summaries: [MatrixSessionSummary], doctorOid: String, businessId: String) {
    for summary in summaries {
      if let existing = session(matrixSessionId: summary.sessionId) {
        if let topic = summary.cleanTopic, existing.title == ChatSession.placeholderTitle {
          existing.title = topic
        }
        continue
      }
      modelContext.insert(ChatSession.remote(summary, doctorOid: doctorOid, businessId: businessId))
    }
    save()
  }

  /// Matrix session whose messages still need importing, or nil.
  func matrixSessionNeedingHistory(sessionId: String) -> String? {
    guard let session = session(id: sessionId), !session.historyLoaded else { return nil }
    guard messageCount(sessionId: sessionId) == 0 else {
      /// Chats started on this device already hold their messages.
      session.historyLoaded = true
      save()
      return nil
    }
    return session.matrixSessionId
  }

  /// Imports server messages into a chat that has none yet.
  func importHistory(_ messages: [MatrixHistoryMessage], sessionId: String) {
    guard let session = session(id: sessionId), messageCount(sessionId: sessionId) == 0 else { return }

    let imported = ChatMessage.imported(from: messages, sessionId: sessionId, startingAt: session.createdAt)
    imported.forEach(modelContext.insert)
    session.historyLoaded = true
    if let last = imported.last {
      session.updatedAt = max(session.updatedAt, last.createdAt)
    }
    save()
  }
}
