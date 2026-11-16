//
//  ChatSync.swift
//  ChatBotAiPackage
//
//  Brings server history into the device cache. The device stays the source of
//  truth: server data only fills in chats and messages the device does not have.
//

import Foundation

enum ChatSync {

  static func syncSessions(doctorOid: String, businessId: String) async {
    do {
      let summaries = try await MatrixClient.shared.listSessions()
      await ChatStore.shared.mergeRemoteSessions(summaries, doctorOid: doctorOid, businessId: businessId)
    } catch {
      print("#ChatSync session list failed: \(error)")
    }
  }

  static func syncMessages(sessionId: String) async {
    guard let matrixSessionId = await ChatStore.shared.matrixSessionNeedingHistory(sessionId: sessionId) else { return }
    do {
      let messages = try await MatrixClient.shared.messages(matrixSessionId: matrixSessionId)
      await ChatStore.shared.importHistory(messages, sessionId: sessionId)
    } catch {
      print("#ChatSync history failed: \(error)")
    }
  }
}
