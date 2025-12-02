//
//  QueryHelper.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 13/02/25.
//

import SwiftData
import CoreData
import Foundation

// Sessions
final class QueryHelper {
//  func fetchSessions(using oid: String) -> FetchDescriptor<SessionDataModel> {
//
//  }
}

// Messages

extension QueryHelper {
  static func fetchMessage(
    messageID: Int,
    sessionID: String
  ) -> FetchDescriptor<ChatMessageModel> {
    
    var fetchDescriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate{
        (($0.sessionId == sessionID) && ($0.msgId == messageID))
      },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)]
    )
    fetchDescriptor.fetchLimit = 1
    return fetchDescriptor
    
  }
}

// MARK: - Core data

//extension QueryHelper {
//  /// Fetch message with messageID and sessionID
//  static func fetchMessage(
//    messageID: Int,
//    sessionID: String,
//    context: NSManagedObjectContext
//  ) -> NSFetchRequest<ChatData>? {
//    let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
//    fetchRequest.predicate = NSPredicate(format: "toSessionData.sessionId == %@ AND messageID == %d", sessionID, messageID)
//    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: false)]
//    fetchRequest.fetchLimit = 1
//    return fetchRequest
//  }
//  
//  static func fetchSession(sessionID: String) -> NSFetchRequest<SessionData> {
//    let fetchRequest: NSFetchRequest<SessionData> = SessionData.fetchRequest()
//    fetchRequest.predicate = NSPredicate(format: "sessionId == %@", sessionID)
//    fetchRequest.fetchLimit = 1
//    return fetchRequest
//  }
//  
////  static func fetchMessage(
////    messageID: Int,
////    sessionID: UUID,
////    context: NSManagedObjectContext
////  ) throws -> ChatData? {
////    let fetchRequest: NSFetchRequest<ChatData> = ChatData.fetchRequest()
////    fetchRequest.predicate = NSPredicate(format: "toSessionData.sessionID == %@ AND messageID == %d", sessionID as CVarArg, messageID)
////    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "messageID", ascending: false)]
////    fetchRequest.fetchLimit = 1
////    
////    let results = try context.fetch(fetchRequest)
////    return results.first
////  }
//}
//
