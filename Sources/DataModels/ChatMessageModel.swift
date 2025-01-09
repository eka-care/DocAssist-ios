//
//  ChatMessageModel.swift
//  Chatbot
//
//  Created by Brunda B on 10/11/24.
//

import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

@Model
public class ChatMessageModel: Identifiable {
  public var msgId: Int
  public var role: MessageRole
  public var messageFiles: [Int]?
  public var messageText: String?
  public var htmlString: String?
  public var createdAt: Int
  public var sessionData: SessionDataModel?
  
  init(
    msgId: Int,
    role: MessageRole,
    messageFiles: [Int]? = nil,
    messageText: String? = nil,
    htmlString: String? = nil,
    createdAt: Int,
    sessionData: SessionDataModel
    
  ) {
    self.msgId = msgId
    self.role = role
    self.messageFiles = messageFiles
    self.messageText = messageText
    self.htmlString = htmlString
    self.createdAt = createdAt
    self.sessionData = sessionData
  }
}

public enum MessageRole: String, Codable {
  case user
  case Bot
  case custom
}
