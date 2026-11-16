//
//  ChatStore+MatrixLinks.swift
//  ChatBotAiPackage
//
//  Lets `MatrixClient` find and save the Matrix session behind a chat.
//

import Foundation

extension ChatStore: MatrixSessionLinks {
  func matrixSessionId(forChat chatId: String) -> String? {
    session(id: chatId)?.matrixSessionId
  }

  func link(chat chatId: String, toMatrixSession matrixSessionId: String) {
    session(id: chatId)?.matrixSessionId = matrixSessionId
    save()
  }

  func unlink(chat chatId: String) {
    session(id: chatId)?.matrixSessionId = nil
    save()
  }
}
