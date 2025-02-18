//
//  ChatMessageModel.swift
//  Chatbot
//
//  Created by Brunda B on 10/11/24.
//

import Foundation
import SwiftData

public typealias ChatMessageModel = ChatMessageV1.ChatMessageModelV1

public enum ChatMessageV1: VersionedSchema {
  
  public nonisolated(unsafe) static let versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
  
  public static var models: [any PersistentModel.Type] {
    [ChatMessageModelV1.self]
  }
  
  @Model
  public final class ChatMessageModelV1: Identifiable, Sendable {
    public var msgId: Int
    public var role: MessageRole
    public var messageFiles: [Int]?
    public var messageText: String?
    public var htmlString: String?
    public var createdAt: Int
    public var sessionId: String
    
    // MARK: - Migration
    public var imageUrls: [String]?
    
    init(
      msgId: Int,
      role: MessageRole,
      messageFiles: [Int]? = nil,
      messageText: String? = nil,
      htmlString: String? = nil,
      createdAt: Int,
      sessionId: String,
      imageUrls: [String]? = nil
    ) {
      self.msgId = msgId
      self.role = role
      self.messageFiles = messageFiles
      self.messageText = messageText
      self.htmlString = htmlString
      self.createdAt = createdAt
      self.sessionId = sessionId
      self.imageUrls = imageUrls
    }
  }
}
public enum MessageRole: String, Codable {
  case user
  case Bot
  case custom
}
