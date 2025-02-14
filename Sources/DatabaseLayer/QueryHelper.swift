//
//  QueryHelper.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 13/02/25.
//

import SwiftData
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
    print("#BB Fetching message with ID: \(messageID) in session: \(sessionID)")
    var fetchDescriptor = FetchDescriptor<ChatMessageModel>(
      predicate: #Predicate{
        (($0.sessionData?.sessionId == sessionID) && ($0.msgId == messageID))
      },
      sortBy: [SortDescriptor(\ChatMessageModel.msgId, order: .reverse)]
    )
    fetchDescriptor.fetchLimit = 1
    return fetchDescriptor
    
  }
  

}
