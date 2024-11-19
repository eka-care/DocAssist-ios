//
//  ChatMessageModel.swift
//  Chatbot
//
//  Created by Brunda B on 10/11/24.
//

import Foundation
import SwiftData

@Model
class ChatMessageModel: Identifiable {
//  @Attribute(.unique) var id: UUID
  var msgId: Int
  var role: MessageRole
  var messageFiles: [Int]?
  var messageText: String?
  var htmlString: String?
  var createdAt: Int
  var sessionData: SessionDataModel?
  
  init(
    msgId: Int,
    role: MessageRole,
    messageFiles: [Int]? = nil,
    messageText: String? = nil,
    htmlString: String? = nil,
    createdAt: Int,
    sessionData: SessionDataModel
    
  ) {
//    self.id = UUID()
    self.msgId = msgId
    self.role = role
    self.messageFiles = messageFiles
    self.messageText = messageText
    self.htmlString = htmlString
    self.createdAt = createdAt
    self.sessionData = sessionData
  }
}

enum MessageRole: String, Codable {
  case user
  case Bot
  case custom
}
