//
//  QueueConfigRepo.swift
//  Chatbot
//
//  Created by Brunda B on 11/11/24.
//

import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

@MainActor
final class QueueConfigRepo1 {
  var modelContext: ModelContext!
  
  static let shared = QueueConfigRepo1()
  private init() { }
  
  func getLastMessageIdUsingSessionId(sessionId: String) -> Int? {
    
    var fetchDescriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate{ $0.sessionData?.sessionId == sessionId },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)])
    
    fetchDescriptor.fetchLimit = 1
    
    let lastMessage = try? modelContext.fetch(fetchDescriptor)
    return lastMessage?.first?.msgId
  }
  
  func SaveTitle(sessionId: String, title: String) {
    
    var fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == sessionId }
    )
    
    fetchDescriptor.fetchLimit = 1
    
    let session = try? modelContext.fetch(fetchDescriptor)
    session?.first?.title = title
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
      print("Error saving data: \(error)")
    }
  }
  
  func deleteSession(sessionId: String) {
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
    do {
      return try modelContext.fetch(FetchDescriptor<SessionDataModel>())
    } catch {
      print("Encountered error in fetching the data \(error.localizedDescription)")
      return []
    }
  }
}
