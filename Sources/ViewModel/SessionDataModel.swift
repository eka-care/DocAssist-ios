//
//  SessionDataModel.swift
//  Chatbot
//
//  Created by Brunda B on 12/11/24.
//

import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

@available(iOS 17, *)
@Model
class SessionDataModel {
  var userId = UUID()
  @Attribute(.unique) var sessionId: String
  var createdAt: Date
  var lastUpdatedAt: Date
  var title: String
  @Relationship(deleteRule: .cascade) var chatMessages: [ChatMessageModel]
  
  init(userId: UUID = UUID(), sessionId: String, createdAt: Date, lastUpdatedAt: Date, title: String = "", chatMessages: [ChatMessageModel] = []) {
    self.userId = userId
    self.sessionId = sessionId
    self.createdAt = createdAt
    self.lastUpdatedAt = lastUpdatedAt
    self.title = title
    self.chatMessages = chatMessages
  }
}
