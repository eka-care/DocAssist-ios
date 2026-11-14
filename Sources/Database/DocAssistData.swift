//
//  DocAssistData.swift
//  ChatBotAiPackage
//

import Foundation

/// Data DocAssist keeps on the device: the chat cache and the Matrix tokens.
public enum DocAssistData {
  public static func clearAll() {
    MatrixTokenStore.clearAll()
    Task { await ChatStore.shared.deleteAll() }
  }
}
