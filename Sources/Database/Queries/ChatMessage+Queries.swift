//
//  ChatMessage+Queries.swift
//  ChatBotAiPackage
//
//  Fetch descriptors and id rules for chat messages.
//

import Foundation
import SwiftData

extension ChatMessage {
  static func inSession(_ sessionId: String) -> FetchDescriptor<ChatMessage> {
    FetchDescriptor(
      predicate: #Predicate { $0.sessionId == sessionId },
      sortBy: [SortDescriptor(\.sequence)]
    )
  }

  static func withId(_ id: String) -> FetchDescriptor<ChatMessage> {
    var descriptor = FetchDescriptor<ChatMessage>(predicate: #Predicate { $0.id == id })
    descriptor.fetchLimit = 1
    return descriptor
  }

  /// The highest-sequence message of a chat.
  static func last(inSession sessionId: String) -> FetchDescriptor<ChatMessage> {
    var descriptor = FetchDescriptor<ChatMessage>(
      predicate: #Predicate { $0.sessionId == sessionId },
      sortBy: [SortDescriptor(\.sequence, order: .reverse)]
    )
    descriptor.fetchLimit = 1
    return descriptor
  }

  /// Messages whose text contains `text`. Filter the role after fetching:
  /// enum comparisons are unreliable inside SwiftData predicates.
  static func containing(_ text: String) -> FetchDescriptor<ChatMessage> {
    FetchDescriptor(predicate: #Predicate { $0.text?.localizedStandardContains(text) ?? false })
  }

  /// Id of the assistant reply to a user message; stable, so streaming upserts one row.
  static func replyId(to userMessageId: String) -> String {
    "\(userMessageId)-reply"
  }
}
