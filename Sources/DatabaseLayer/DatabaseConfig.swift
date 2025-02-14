//
//  QueueConfigRepo.swift
//  Chatbot
//
//  Created by Brunda B on 11/11/24.
//

import Foundation
import SwiftData

@ModelActor
final actor DatabaseConfig: Sendable {
  private let lock = NSLock()
  
  static var shared: DatabaseConfig!
  
  public static func setup(modelContainer: ModelContainer) {
    shared = DatabaseConfig(modelContainer: modelContainer)
  }
  
  func getLastMessageIdUsingSessionId(sessionId: String) -> Int? {
    lock.lock()
    defer{ lock.unlock() }
    
    var fetchDescriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate{ $0.sessionData?.sessionId == sessionId },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)])
    
    fetchDescriptor.fetchLimit = 1
    
    let lastMessage = try? modelContext.fetch(fetchDescriptor)
    return lastMessage?.first?.msgId
  }
  
  
  // Update
  func SaveTitle(sessionId: String, title: String) {
    lock.lock()
    defer{ lock.unlock() }
    
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
      try modelContext.transaction {
        do {
          try modelContext.save()
        } catch {
          print("Error saving data: \(error)")
        }
      }
    }catch {
      print("Error saving data: \(error)")
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
  
  func getMessageBySessionId(sessionId: String) -> [ChatMessageModel] {
    lock.lock()
    defer{ lock.unlock() }
    
    let fetchDescriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { message in
        message.sessionData?.sessionId == sessionId
      },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .forward)])
    
    do {
      return try modelContext.fetch(fetchDescriptor)
    } catch {
      print("Encountered error in fetching the data \(error.localizedDescription)")
      return []
    }
  }
  
  func getAllSessions() -> [SessionDataModel] {
    lock.lock()
    defer{ lock.unlock() }
    
    do {
      return try modelContext.fetch(FetchDescriptor<SessionDataModel>())
    } catch {
      print("Encountered error in fetching the data \(error.localizedDescription)")
      return []
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
  
  func fetchPatientName(fromSessionId ssid: String, context: ModelContext) throws -> String {
    lock.lock()
    defer{ lock.unlock() }
    
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == ssid }
    )
    let results = try context.fetch(fetchDescriptor)
    return results.first?.subTitle ?? ""
  }

  func fetchChatUsing(oid: String) -> [SessionDataModel] {
    lock.lock()
    defer{ lock.unlock() }
    
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate<SessionDataModel> { session in
        session.oid == oid
      },
      sortBy: [SortDescriptor(\SessionDataModel.lastUpdatedAt, order: .reverse)]
    )
    
    do {
      let results = try modelContext.fetch(fetchDescriptor)
      return results
    } catch {
      print("Error fetching sessions for patient \(oid): \(error)")
      return []
    }
  }
  
  func fetchAllChatMessageFromSession(session: String) -> [ChatMessageModel] {
    lock.lock()
    defer{ lock.unlock() }
    
    debugPrint("#BB: fetchchat")
    let descriptor = FetchDescriptor<ChatMessageModel>(predicate: #Predicate{ $0.sessionData?.sessionId == session })
    do {
      let allMessages = try modelContext.fetch(descriptor)
      return allMessages
    } catch {
      print("Error fetching all chats: \(error.localizedDescription)")
      return []
    }
  }
  
//  func updateMessage(newMessage: String, sessionId: String, msgId: Int) {
//    lock.lock()
//    defer{ lock.unlock() }
//    
//    var descriptor = FetchDescriptor<ChatMessageModel>(predicate: #Predicate{ (($0.sessionData?.sessionId == sessionId) && ($0.msgId == msgId)) })
//    descriptor.fetchLimit = 1
//    do {
//      let message = try modelContext.fetch(descriptor).first
//      message?.messageText = newMessage
//      saveData()
//    } catch {
//      debugPrint("error in updating message \(error.localizedDescription)")
//    }
//  }
  
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
  
  func saveChatMessage() {
    do {
      try modelContext.save()
    } catch {
      print("Error saving data: \(error)")
    }
  }
  
  func getLastMessageId(sessionId: String) -> Int? {
    
    var fetchDescriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate<ChatMessageModel> { message in
        message.sessionData?.sessionId == sessionId
      },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)]
    )
    fetchDescriptor.fetchLimit = 1
    
    do {
      let messages = try modelContext.fetch(fetchDescriptor)
      return messages.first?.msgId
    } catch {
      print("Error fetching last message id: \(error)")
      return nil
    }
  }
  
  func fetchAllSessions() -> [SessionDataModel] {
    
    do {
      return try modelContext.fetch(FetchDescriptor<SessionDataModel>())
    } catch {
      print("Error fetching all sessions: \(error)")
      return []
    }
  }
  
  func appendChatMessage(message: String, sessionId: String, messageId: Int, role: MessageRole, imageUrls: [String]?) {
    
    if let fetchedSession = try? fetchSession(bySessionId: sessionId) {
      let chat = ChatMessageModel(
        msgId: messageId,
        role: role,
        messageFiles: nil,
        messageText: message,
        htmlString: nil,
        createdAt: 0,
        sessionData: fetchedSession,
        imageUrls: imageUrls
      )
      fetchedSession.chatMessages.append(chat)
    }
    saveData()
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
    if let fetchedSession = try? fetchSession(bySessionId: sessionId) {
      let chat = ChatMessageModel(
        msgId: messageId,
        role: role,
        messageFiles: nil,
        messageText: message,
        htmlString: nil,
        createdAt: 0,
        sessionData: fetchedSession,
        imageUrls: imageUrls
      )
      fetchedSession.chatMessages.append(chat)
      print("#BB Chat message created session: \(chat.sessionData?.sessionId ?? "empty")")
      saveData()
      return chat
    }
    return nil
  }
}

// Read
extension DatabaseConfig {
  func fetchMessages(fetchDescriptor: FetchDescriptor<ChatMessageModel>) -> [ChatMessageModel] {
    do {
      let messages = try modelContext.fetch(fetchDescriptor)
      print("#BB messages \(messages.count)")
      return messages
    } catch {
      print("Error fetching last message id: \(error)")
      return []
    }
  }
  
  func fetchSessions(fetchDescriptor: FetchDescriptor<SessionDataModel>) -> [SessionDataModel] {
    do {
      lock.lock()
      defer{ lock.unlock() }
      let sessions = try modelContext.fetch(fetchDescriptor)
      return sessions
    } catch {
      print("Error fetching last message id: \(error)")
      return []
    }
  }
}

// Update
extension DatabaseConfig {
  func updateMessage(
    messageID: Int,
    currentSessionID: String,
    messageText: String? = nil
  ) async {
       
    let fetchDescriptor = QueryHelper.fetchMessage(
      messageID: messageID,
      sessionID: currentSessionID
    )
    do {
      let messages = try modelContext.fetch(fetchDescriptor)
      print("Message ")
      await MainActor.run {
        messages.first?.msgId = messageID
        if let messageText {
          messages.first?.messageText = messageText
        }
      }
    } catch {
      debugPrint("Error updating message \(error.localizedDescription)")
    }
  }
}

// Delete
