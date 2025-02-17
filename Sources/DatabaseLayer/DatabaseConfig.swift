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
    
    do {
      try modelContext.save()
    } catch {
      print("Error saving title: \(error)")
    }
  }
  
  func saveData() {
    do {
      try modelContext.save()
    } catch {
      print("#LD Error saving data: \(error)")
    }
  }
  
  func deleteSession(sessionId: String) {
    lock.lock()
    defer{ lock.unlock() }
    
    do {
      var fetchDescriptor = FetchDescriptor<SessionDataModel>(
        predicate: #Predicate<SessionDataModel> { session in
          session.sessionId == sessionId
        }
      )
      
      fetchDescriptor.fetchLimit = 1
      
      if let sessions = try? modelContext.fetch(fetchDescriptor),
         let sessionToDelete = sessions.first {
        modelContext.delete(sessionToDelete)
        
        // Save changes
        try modelContext.save()
        print("Successfully deleted session: \(sessionId)")
      } else {
        print("No session found with ID: \(sessionId)")
      }
    } catch {
      print("Error deleting session: \(error.localizedDescription)")
    }
  }
  
  func deleteAllValues() {
    lock.lock()
    defer{ lock.unlock() }
    
    do {
      try modelContext.delete(model: SessionDataModel.self)
      try modelContext.delete(model: ChatMessageModel.self)
    } catch {
      print("Error deleting all values: \(error)")
    }
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
  
  func saveChatMessage() {
    do {
      try modelContext.save()
    } catch {
      print("Error saving data: \(error)")
    }
  }
}

// Create
extension DatabaseConfig {
  func createMessage(
    message: String,
    sessionId: String,
    messageId: Int,
    role: MessageRole,
    imageUrls: [String]?
  ) -> ChatMessageModel? {
    let chat = ChatMessageModel(
      msgId: messageId,
      role: role,
      messageFiles: nil,
      messageText: message,
      htmlString: nil,
      createdAt: 0,
      sessionId: sessionId,
      imageUrls: imageUrls
    )
    insertMessage(message: chat)
    
    print("#BB Chat message created session: \(chat.sessionId)")
    saveData()
    
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .addedMessage, object: nil)
    }
    
    return chat
  }
}

// Upsert
extension DatabaseConfig {
  func upsertMessageV2(responseMessage: String, userChat: ChatMessageModel) {
//    debugPrint("#LD Before lock")
//    upsertLock.lock()
//    defer {
//      debugPrint("#LD Going to unlock")
//      upsertLock.unlock()
//    }
    
    let sessionId = userChat.sessionId
    let streamMessageId = userChat.msgId + 1
    
    /// Check if message already exists
    if let messageToUpdate = try? fetchMessage(bySessionId: sessionId, messageId: streamMessageId) {
      
      DispatchQueue.main.async {
        messageToUpdate.messageText = responseMessage
        
        NotificationCenter.default.post(name: .addedMessage, object: nil)
        
      }
      return
    }
    
    let _ = createMessage(
      message: responseMessage,
      sessionId: sessionId,
      messageId: streamMessageId,
      role: .Bot,
      imageUrls: nil
    )
    
    debugPrint("#LD End of function")
  }
}
