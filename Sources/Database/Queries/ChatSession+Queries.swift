//
//  ChatSession+Queries.swift
//  ChatBotAiPackage
//
//  Fetch descriptors for chats, shared by `@Query` in views and by `ChatStore`.
//

import Foundation
import SwiftData

extension ChatSession {
  static let placeholderTitle = "New Chat"

  /// Visible chats of one doctor in one business, newest first.
  static func visible(doctorOid: String, businessId: String) -> FetchDescriptor<ChatSession> {
    FetchDescriptor(
      predicate: #Predicate { $0.deletedAt == nil && $0.doctorOid == doctorOid && $0.businessId == businessId },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
  }

  /// Visible chats about one patient, newest first.
  static func visible(patientOid: String, doctorOid: String, businessId: String) -> FetchDescriptor<ChatSession> {
    FetchDescriptor(
      predicate: #Predicate {
        $0.deletedAt == nil && $0.patientOid == patientOid && $0.doctorOid == doctorOid && $0.businessId == businessId
      },
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
  }

  static func withId(_ id: String) -> FetchDescriptor<ChatSession> {
    var descriptor = FetchDescriptor<ChatSession>(predicate: #Predicate { $0.id == id })
    descriptor.fetchLimit = 1
    return descriptor
  }

  /// Includes hidden chats, so a deleted chat is recognised during a server sync.
  static func withMatrixSessionId(_ matrixSessionId: String) -> FetchDescriptor<ChatSession> {
    var descriptor = FetchDescriptor<ChatSession>(predicate: #Predicate { $0.matrixSessionId == matrixSessionId })
    descriptor.fetchLimit = 1
    return descriptor
  }
}
