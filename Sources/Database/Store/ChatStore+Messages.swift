//
//  ChatStore+Messages.swift
//  ChatBotAiPackage
//
//  Messages written on the device: the doctor's message, the streamed reply,
//  Voice-to-Rx cards; plus reply search.
//

import Foundation
import SwiftData

extension ChatStore {

  /// Appends the doctor's message and returns its id. The first message names the chat.
  @discardableResult
  func appendUserMessage(sessionId: String, text: String, imageUrls: [String]?) -> String {
    let message = ChatMessage(
      id: UUID().uuidString,
      sessionId: sessionId,
      sequence: nextSequence(sessionId: sessionId),
      role: .user,
      text: text,
      imageUrls: imageUrls
    )
    modelContext.insert(message)
    if let session = session(id: sessionId) {
      if session.title == ChatSession.placeholderTitle, !text.isEmpty {
        session.title = text
      }
      session.updatedAt = message.createdAt
    }
    save()
    return message.id
  }

  /// Creates or updates the assistant reply to `userMessageId` while it streams.
  func upsertReply(to userMessageId: String, sessionId: String, text: String, suggestions: [String]?) {
    let replyId = ChatMessage.replyId(to: userMessageId)
    if let reply = message(id: replyId) {
      reply.text = text
      reply.suggestions = suggestions
    } else {
      modelContext.insert(
        ChatMessage(
          id: replyId,
          sessionId: sessionId,
          sequence: nextSequence(sessionId: sessionId),
          role: .assistant,
          text: text,
          suggestions: suggestions
        )
      )
      session(id: sessionId)?.updatedAt = .now
    }
    save()
  }

  func appendVoiceToRx(sessionId: String, audioSessionId: UUID) {
    modelContext.insert(
      ChatMessage(
        id: UUID().uuidString,
        sessionId: sessionId,
        sequence: nextSequence(sessionId: sessionId),
        role: .voiceToRx,
        v2RxAudioSessionId: audioSessionId
      )
    )
    session(id: sessionId)?.updatedAt = .now
    save()
  }

  func deleteVoiceToRxMessages(audioSessionId: UUID) {
    try? modelContext.delete(model: ChatMessage.self, where: #Predicate { $0.v2RxAudioSessionId == audioSessionId })
    save()
  }

  /// Ids of chats with an assistant message containing `text`.
  func sessionIds(withReplyContaining text: String) -> Set<String> {
    let matches = (try? modelContext.fetch(ChatMessage.containing(text))) ?? []
    return Set(matches.filter { $0.role == .assistant }.map(\.sessionId))
  }
}
