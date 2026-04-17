//
//  QueueConfigRepo.swift
//  Chatbot
//
//  Created by Brunda B on 11/11/24.
//

import Foundation
import SwiftData

@ModelActor
public final actor DatabaseConfig {
  
  public static var shared: DatabaseConfig!
  
  public static func setup(modelContainer: ModelContainer) {
    shared = DatabaseConfig(modelContainer: modelContainer)
  }
  
  // Update
  func saveTitle(sessionId: String, title: String) async {

    var fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == sessionId }
    )

    fetchDescriptor.fetchLimit = 1

    let session = try? modelContext.fetch(fetchDescriptor)

    session?.first?.title = title
    session?.first?.lastUpdatedAt = Date()

    await saveData()
  }

  func updateSessionToken(sessionId: String, sessionToken: String) async {
    var fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == sessionId }
    )
    fetchDescriptor.fetchLimit = 1
    let session = try? modelContext.fetch(fetchDescriptor)
    session?.first?.sessionToken = sessionToken
    session?.first?.lastUpdatedAt = Date()
    await saveData()
  }

  func saveData() async {
    do {
      try modelContext.save()
    } catch {
      print("Error saving data: \(error)")
    }
  }

  func deleteSession(sessionId: String) async {
    try? modelContext.delete(model: SessionDataModel.self, where: #Predicate{ $0.sessionId == sessionId })
    await saveData()
  }
  
  func deleteAllValues() async {
    do {
      try modelContext.delete(model: SessionDataModel.self)
      try modelContext.delete(model: ChatMessageModel.self)
      await saveData()
    } catch {
      print("Error deleting all values: \(error)")
    }
  }

  // Delete chat message using voicetorxsessionid
  func deleteChatMessageByVoiceToRxSessionId(v2RxAudioSessionId: UUID?) async {
    guard let v2RxAudioSessionId else { return }
    try? modelContext.delete(model: ChatMessageModel.self, where: #Predicate { $0.v2RxAudioSessionId == v2RxAudioSessionId })
    await saveData()
  }
  
  func fetchSessionId(fromOid oid: String, userDocId: String, userBId: String) throws -> [SessionDataModel] {
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.userBId == userBId && $0.userDocId == userDocId && $0.oid == oid }
    )
    let results = try modelContext.fetch(fetchDescriptor)
    return results
  }
  
  func fetchSessionIdwithoutoid(userDocId: String, userBId: String) throws -> [SessionDataModel] {
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.userBId == userBId && $0.userDocId == userDocId}
    )
    let results = try modelContext.fetch(fetchDescriptor)
    return results
  }
  
  func insertSession(session: SessionDataModel) async {
    modelContext.insert(session)
  }
  
  func fetchSession(bySessionId sessionId: String) throws -> SessionDataModel? {
    let descriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate<SessionDataModel> { session in
        session.sessionId == sessionId
      }
    )
    return try modelContext.fetch(descriptor).first
  }
  
  func fetchMessage(bySessionId sessionId: String, messageId: Int) throws -> ChatMessageModel? {
    var descriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { session in
        session.sessionId == sessionId && session.msgId == messageId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
  
  func fetchAllMessages(bySessionId sessionId: String) throws -> [ChatMessageModel]? {
    let descriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { session in
        session.sessionId == sessionId
      },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)
  }
  
  func insertMessage(message: ChatMessageModel) async {
    modelContext.insert(message)
  }
  
  func searchBotMessages(searchText: String) async throws -> [ChatMessageModel] {
      let descriptor = FetchDescriptor<ChatMessageModel>(
          predicate: #Predicate<ChatMessageModel> { message in
            message.messageText?.contains(searchText) ?? false
          }
      )
      return try modelContext.fetch(descriptor)
  }
  
  func isOidPresent(sessionId: String) async throws -> String {
    let descriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == sessionId && ($0.oid != nil || $0.oid != "")}
      )
    return try modelContext.fetch(descriptor).first?.oid ?? ""
    
  }
}

// Create
extension DatabaseConfig {
  func createMessage(
    message: String? = nil,
    sessionId: String,
    messageId: Int,
    role: MessageRole,
    imageUrls: [String]?,
    v2RxAudioSessionId: UUID? = nil,
    suggestions: [String]? = nil,
    multiSelect: Bool? = nil
  ) async -> ChatMessageModel? {
    let chat = ChatMessageModel(
      msgId: messageId,
      role: role,
      messageFiles: nil,
      messageText: message,
      htmlString: nil,
      createdAt: 1,
      sessionId: sessionId,
      imageUrls: imageUrls,
      v2RxAudioSessionId: v2RxAudioSessionId,
      createdAtDate: .now,
      suggestions: suggestions,
      multiSelect: multiSelect
    )

    if let session = try? fetchSession(bySessionId: sessionId) {
      session.lastUpdatedAt = .now
    }

    modelContext.insert(chat)
    await saveData()

    return chat
  }

  /// Creates a user message and — if it is the first message — updates the session title,
  /// all in a single actor turn (one cross-actor hop instead of two).
  func createUserMessageWithTitle(
    message: String,
    sessionId: String,
    messageId: Int,
    imageUrls: [String]?
  ) async -> ChatMessageModel? {
    let chat = ChatMessageModel(
      msgId: messageId,
      role: .user,
      messageFiles: nil,
      messageText: message,
      htmlString: nil,
      createdAt: 1,
      sessionId: sessionId,
      imageUrls: imageUrls,
      v2RxAudioSessionId: nil,
      createdAtDate: .now,
      suggestions: nil,
      multiSelect: nil
    )

    if let session = try? fetchSession(bySessionId: sessionId) {
      session.lastUpdatedAt = .now
      // Set title from first user message in one save — no second actor hop needed.
      if messageId == 1 {
        session.title = message
      }
    }

    modelContext.insert(chat)
    await saveData()

    return chat
  }
}

// Upsert
extension DatabaseConfig {
  func upsertMessageV2(responseMessage: String, userChat: ChatMessageModel?, suggestions: [String]?, multiSelect: Bool?) async {

    guard let userChat else { return }
    let sessionId = userChat.sessionId
    let streamMessageId = userChat.msgId + 1
    /// Check if message already exists
    if let messageToUpdate = try? fetchMessage(bySessionId: sessionId, messageId: streamMessageId) {

      if messageToUpdate.messageText == nil {
        messageToUpdate.messageText = responseMessage
      } else {
        messageToUpdate.messageText! += responseMessage
      }
      if let suggestions, !suggestions.isEmpty {
        messageToUpdate.suggestions = suggestions
      }
      if let multiSelect {
        messageToUpdate.multiselect = multiSelect
      }
      await saveData()

      return
    }

    let _ = await createMessage(
      message: responseMessage,
      sessionId: sessionId,
      messageId: streamMessageId,
      role: .Bot,
      imageUrls: nil,
      suggestions: suggestions,
      multiSelect: multiSelect
    )
  }
}

extension DatabaseConfig {
    
    public func appendSuggestions(sessionId: String, msgId: Int, suggestions: [String]) async {
        if let messageToUpdate = try? fetchMessage(bySessionId: sessionId, messageId: msgId) {
            messageToUpdate.suggestions?.append(contentsOf: suggestions)
            await saveData()
        }
    }
    
    func fetchLatestMessage(bySessionId sessionId: String) throws -> Int {
        var descriptor = FetchDescriptor<ChatMessageModel>(
            predicate: #Predicate<ChatMessageModel> { session in
                session.sessionId == sessionId
            },
            sortBy: [SortDescriptor(\.msgId, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first?.msgId ?? 0
    }
  
  func hasMessages(forSessionId sessionId: String) async -> Bool {
    var descriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { message in
        message.sessionId == sessionId
      }
    )
    descriptor.fetchLimit = 1
    
    return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
  }
  
  public func createSession(
    subTitle: String?,
    oid: String = "",
    userDocId: String,
    userBId: String,
    sessionId: String,
    sessionToken: String
  ) async -> String {
    let currentDate = Date()
    let ssid = UUID().uuidString
    let createSessionModel = SessionDataModel(
      sessionId: sessionId,
      createdAt: currentDate,
      lastUpdatedAt: currentDate,
      title: "New Chat",
      subTitle: subTitle,
      oid: oid,
      userDocId: userDocId,
      userBId: userBId,
      sessionToken: sessionToken
    )
    await insertSession(session: createSessionModel)
    await saveData()
    return ssid
  }
}
