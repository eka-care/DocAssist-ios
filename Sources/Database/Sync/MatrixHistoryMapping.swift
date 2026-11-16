//
//  MatrixHistoryMapping.swift
//  ChatBotAiPackage
//
//  Turns Matrix wire types into cache rows. Keeps server quirks
//  (empty topics, null timestamps, elicitation-only messages) out of the store.
//

import Foundation

extension MatrixSessionSummary {
  /// The topic, or nil when the server sent none.
  var cleanTopic: String? {
    let topic = topic?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return topic.isEmpty ? nil : topic
  }
}

extension ChatSession {
  /// A chat that exists only on the server. Its id is the Matrix session id.
  /// The list API does not say which patient it is about, so it is a general chat.
  static func remote(_ summary: MatrixSessionSummary, doctorOid: String, businessId: String) -> ChatSession {
    ChatSession(
      id: summary.sessionId,
      matrixSessionId: summary.sessionId,
      title: summary.cleanTopic ?? placeholderTitle,
      patientOid: nil,
      patientName: nil,
      doctorOid: doctorOid,
      businessId: businessId,
      createdAt: summary.createdAt.map { Date(timeIntervalSince1970: $0) } ?? .now
    )
  }
}

extension ChatMessage {
  /// Server messages as rows, in order. An elicitation-only message shows its
  /// prompt as text and its options as suggestions; empty messages are skipped.
  /// Messages without a timestamp take the previous message's time.
  static func imported(from messages: [MatrixHistoryMessage], sessionId: String, startingAt start: Date) -> [ChatMessage] {
    var rows: [ChatMessage] = []
    var date = start
    for message in messages {
      let elicitation = message.elicitations?.first?.input
      let content = message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let text = content.isEmpty ? (elicitation?.text ?? "") : content
      let options = elicitation?.options?.map(\.label)
      guard !text.isEmpty || !(options ?? []).isEmpty else { continue }

      date = message.timestamp.map { Date(timeIntervalSince1970: $0) } ?? date
      rows.append(
        ChatMessage(
          id: "\(sessionId)/\(message.id)",
          sessionId: sessionId,
          sequence: rows.count + 1,
          role: message.role == "user" ? .user : .assistant,
          text: text,
          suggestions: options,
          createdAt: date
        )
      )
    }
    return rows
  }
}
