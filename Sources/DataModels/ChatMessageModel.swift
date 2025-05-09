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
  
  public nonisolated(unsafe) static let versionIdentifier: Schema.Version = Schema.Version(6, 0, 0)
  
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
    public var imageUrls: [String]?
    public var v2RxAudioSessionId: UUID?
    public var v2RxaudioFileString: String?
    public var createdAtDate: Date?
    public var suggestions: [String]?
    public var transript: String?
    
    init(
      msgId: Int,
      role: MessageRole,
      messageFiles: [Int]? = nil,
      messageText: String? = nil,
      htmlString: String? = nil,
      createdAt: Int,
      sessionId: String,
      imageUrls: [String]? = nil,
      v2RxAudioSessionId: UUID? = nil,
      v2RxaudioFileString: String? = nil,
      createdAtDate: Date? = nil,
      suggestions: [String]? = nil,
      transript: String? = nil
    ) {
      self.msgId = msgId
      self.role = role
      self.messageFiles = messageFiles
      self.messageText = messageText
      self.htmlString = htmlString
      self.createdAt = createdAt
      self.sessionId = sessionId
      self.imageUrls = imageUrls
      self.v2RxAudioSessionId = v2RxAudioSessionId
      self.v2RxaudioFileString = v2RxaudioFileString
      self.createdAtDate = createdAtDate ?? Date()
      self.suggestions = suggestions
      self.transript = transript
    }
  }
}
public enum MessageRole: String, Codable {
  case user
  case Bot
  case custom
}
