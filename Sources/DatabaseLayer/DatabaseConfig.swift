//
//  QueueConfigRepo.swift
//  Chatbot
//
//  Created by Brunda B on 11/11/24.
//

import Foundation
import SwiftData

@ModelActor
final actor DatabaseConfig {
  private let lock = NSLock()
  private let upsertLock = NSLock()
  
  static var shared: DatabaseConfig!
  
  public static func setup(modelContainer: ModelContainer) {
    shared = DatabaseConfig(modelContainer: modelContainer)
  }
  
  // Update
  func saveTitle(sessionId: String, title: String) {
    
    var fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == sessionId }
    )
    
    fetchDescriptor.fetchLimit = 1
    
    let session = try? modelContext.fetch(fetchDescriptor)
    
    session?.first?.title = title
    session?.first?.lastUpdatedAt = Date()
    
    saveData()
  }
  
  func saveData() {
    do {
      try modelContext.save()
    } catch {
      print("Error saving data: \(error)")
    }
  }
  
  func deleteSession(sessionId: String) {
    try? modelContext.delete(model: SessionDataModel.self, where: #Predicate{ $0.sessionId == sessionId })
  }
  
  func deleteAllValues() {
    do {
      try modelContext.delete(model: SessionDataModel.self)
      try modelContext.delete(model: ChatMessageModel.self)
    } catch {
      print("Error deleting all values: \(error)")
    }
  }
  
  // Delet chat message using voicetorxsessionid
  func deleteChatMessageByVoiceToRxSessionId(v2RxAudioSessionId: UUID) {
    try? modelContext.delete(model: ChatMessageModel.self, where: #Predicate { $0.v2RxAudioSessionId == v2RxAudioSessionId })
  }
  
  func fetchSessionId(fromOid oid: String, userDocId: String, userBId: String) throws -> [SessionDataModel] {
    lock.lock()
    defer{ lock.unlock() }
    
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.userBId == userBId && $0.userDocId == userDocId && $0.oid == oid }
    )
    let results = try modelContext.fetch(fetchDescriptor)
    return results
  }
  
  func insertSession(session: SessionDataModel) {
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
    lock.lock()
    defer { lock.unlock() }
    
    var descriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { session in
        session.sessionId == sessionId && session.msgId == messageId }
    )
    descriptor.fetchLimit = 1
    return try modelContext.fetch(descriptor).first
  }
  
  func fetchAllMessages(bySessionId sessionId: String) throws -> [ChatMessageModel]? {
    lock.lock()
    defer { lock.unlock() }
    let descriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { session in
        session.sessionId == sessionId
      },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)]
    )
    return try modelContext.fetch(descriptor)
  }
  
  func insertMessage(message: ChatMessageModel) {
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
    v2RxaudioFileString: String? = nil
  ) -> ChatMessageModel? {
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
      v2RxaudioFileString: v2RxaudioFileString,
      createdAtDate: .now
    )
    
    if let session = try? fetchSession(bySessionId: sessionId) {
      session.lastUpdatedAt = .now
    }
    
    insertMessage(message: chat)
    saveData()
    
    return chat
  }
}

// Upsert
extension DatabaseConfig {
  func upsertMessageV2(responseMessage: String, userChat: ChatMessageModel) {
    let sessionId = userChat.sessionId
    let streamMessageId = userChat.msgId + 1
    
    /// Check if message already exists
    if let messageToUpdate = try? fetchMessage(bySessionId: sessionId, messageId: streamMessageId) {
      
      DispatchQueue.main.async {
        messageToUpdate.messageText = responseMessage
      }
      saveData()
  
      return
    }
    
    let _ = createMessage(
      message: responseMessage,
      sessionId: sessionId,
      messageId: streamMessageId,
      role: .Bot,
      imageUrls: nil
    )
  }
}
