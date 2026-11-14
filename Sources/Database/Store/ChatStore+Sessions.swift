//
//  ChatStore+Sessions.swift
//  ChatBotAiPackage
//
//  Chat lifecycle: create, delete, discard, look up.
//

import Foundation
import SwiftData

extension ChatStore {

  /// Starts a chat on the device. The Matrix session is created later, with the first message.
  func createSession(doctorOid: String, businessId: String, patientOid: String?, patientName: String?) -> String {
    let session = ChatSession(
      title: ChatSession.placeholderTitle,
      patientOid: patientOid?.isEmpty == true ? nil : patientOid,
      patientName: patientName?.isEmpty == true ? nil : patientName,
      doctorOid: doctorOid,
      businessId: businessId
    )
    modelContext.insert(session)
    save()
    return session.id
  }

  /// Removes a chat. One the server knows about stays as a hidden tombstone,
  /// so the next server sync does not bring it back.
  func deleteSession(id: String) {
    guard let session = session(id: id) else { return }
    try? modelContext.delete(model: ChatMessage.self, where: #Predicate { $0.sessionId == id })
    if session.matrixSessionId == nil {
      modelContext.delete(session)
    } else {
      session.deletedAt = .now
    }
    save()
  }

  /// Drops a chat that was opened but never used.
  func discardIfEmpty(id: String) {
    guard let session = session(id: id), session.matrixSessionId == nil, messageCount(sessionId: id) == 0 else { return }
    modelContext.delete(session)
    save()
  }

  func hasSessions(patientOid: String, doctorOid: String, businessId: String) -> Bool {
    let descriptor = ChatSession.visible(patientOid: patientOid, doctorOid: doctorOid, businessId: businessId)
    return ((try? modelContext.fetchCount(descriptor)) ?? 0) > 0
  }

  func patientOid(sessionId: String) -> String? {
    session(id: sessionId)?.patientOid
  }
}
