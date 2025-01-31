//
//  QueueConfigRepo.swift
//  Chatbot
//
//  Created by Brunda B on 11/11/24.
//

import Foundation
import SwiftData

@MainActor
final class DatabaseConfig {
  var modelContext: ModelContext!
  
  static let shared = DatabaseConfig()
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
  
  func deleteAllValues() {
    do {
      try modelContext.delete(model: SessionDataModel.self)
      try modelContext.delete(model: ChatMessageModel.self)
    } catch {
      print("Error deleting all values: \(error)")
    }
  }
  
  func fetchSessionId(fromOid oid: String, userDocId: String, userBId: String, context: ModelContext) throws -> [SessionDataModel] {
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.userBId == userBId && $0.userDocId == userDocId && $0.oid == oid }
    )
    let results = try context.fetch(fetchDescriptor)
    return results
  }
   
  func fetchPatientName (fromSessionId ssid: String, context: ModelContext) throws -> String {
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == ssid }
    )
    let results = try context.fetch(fetchDescriptor)
    return results.first?.subTitle ?? ""
  }
  
  func fetchChatUsing(patientName: String) -> [SessionDataModel] {
    
    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate<SessionDataModel> { session in
        session.subTitle == patientName
      },
      sortBy: [SortDescriptor(\SessionDataModel.lastUpdatedAt, order: .reverse)]
    )
    
    do {
      let results = try modelContext.fetch(fetchDescriptor)
      return results
    } catch {
      print("Error fetching sessions for patient \(patientName): \(error)")
      return []
    }
  }
}
