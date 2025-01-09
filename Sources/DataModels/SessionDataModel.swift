//
//  SessionDataModel.swift
//  Chatbot
//
//  Created by Brunda B on 12/11/24.
//

import Foundation
import SwiftData

public typealias SessionDataModel = SessionDataV1.SessionDataModelV1

public enum SessionDataV1: VersionedSchema {
  
  public nonisolated(unsafe) static let versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
  
  public static var models: [any PersistentModel.Type] {
    [SessionDataModelV1.self]
  }
  
  @Model
  public class SessionDataModelV1 {
    public var userId = UUID()
    @Attribute(.unique) public var sessionId: String
    public var createdAt: Date
    public var lastUpdatedAt: Date
    public var title: String
    public var subTitle: String?
    public var oid: String?
    public var userDocId: String
    public var userBId: String
    @Relationship(deleteRule: .cascade) var chatMessages: [ChatMessageModel]
    
    init(userId: UUID = UUID(), sessionId: String, createdAt: Date, lastUpdatedAt: Date, title: String = "", subTitle: String?, oid: String?, userDocId: String, userBId: String, chatMessages: [ChatMessageModel] = []) {
      self.userId = userId
      self.sessionId = sessionId
      self.createdAt = createdAt
      self.lastUpdatedAt = lastUpdatedAt
      self.title = title
      self.subTitle = subTitle
      self.oid = oid
      self.userDocId = userDocId
      self.userBId = userBId
      self.chatMessages = chatMessages
    }
  }
}
