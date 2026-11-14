//
//  ChatSchemaV1.swift
//  ChatBotAiPackage
//
//  Version 1 of the on-device chat schema. Owned by DocAssist (see `ChatStore`);
//  the host app never registers these models in its own container.
//  A future change adds `ChatSchemaV2` plus a migration plan instead of editing this file.
//

import Foundation
import SwiftData

public typealias ChatSession = ChatSchemaV1.ChatSession
public typealias ChatMessage = ChatSchemaV1.ChatMessage

public enum ChatSchemaV1: VersionedSchema {
  public static let versionIdentifier = Schema.Version(1, 0, 0)

  public static var models: [any PersistentModel.Type] {
    [ChatSession.self, ChatMessage.self]
  }

  @Model
  public final class ChatSession {
    @Attribute(.unique) public private(set) var id: String
    public internal(set) var matrixSessionId: String?
    public internal(set) var title: String
    public internal(set) var patientOid: String?
    public internal(set) var patientName: String?
    public private(set) var doctorOid: String
    public private(set) var businessId: String
    public private(set) var createdAt: Date
    public internal(set) var updatedAt: Date
    var historyLoaded: Bool
    var deletedAt: Date?

    init(
      id: String = UUID().uuidString,
      matrixSessionId: String? = nil,
      title: String,
      patientOid: String?,
      patientName: String?,
      doctorOid: String,
      businessId: String,
      createdAt: Date = .now,
      historyLoaded: Bool = false
    ) {
      self.id = id
      self.matrixSessionId = matrixSessionId
      self.title = title
      self.patientOid = patientOid
      self.patientName = patientName
      self.doctorOid = doctorOid
      self.businessId = businessId
      self.createdAt = createdAt
      self.updatedAt = createdAt
      self.historyLoaded = historyLoaded
      self.deletedAt = nil
    }

    public var isPatientChat: Bool { !(patientOid ?? "").isEmpty }
  }

  @Model
  public final class ChatMessage {
    @Attribute(.unique) public private(set) var id: String
    public private(set) var sessionId: String
    public private(set) var sequence: Int
    public private(set) var role: ChatRole
    public internal(set) var text: String?
    public internal(set) var imageUrls: [String]?
    public internal(set) var suggestions: [String]?
    public private(set) var createdAt: Date
    public private(set) var v2RxAudioSessionId: UUID?

    init(
      id: String,
      sessionId: String,
      sequence: Int,
      role: ChatRole,
      text: String? = nil,
      imageUrls: [String]? = nil,
      suggestions: [String]? = nil,
      createdAt: Date = .now,
      v2RxAudioSessionId: UUID? = nil
    ) {
      self.id = id
      self.sessionId = sessionId
      self.sequence = sequence
      self.role = role
      self.text = text
      self.imageUrls = imageUrls
      self.suggestions = suggestions
      self.createdAt = createdAt
      self.v2RxAudioSessionId = v2RxAudioSessionId
    }
  }
}
