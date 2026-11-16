//
//  ChatRole.swift
//  ChatBotAiPackage
//
//  Who wrote a chat message.
//

import Foundation

public enum ChatRole: String, Codable, Sendable {
  case user
  case assistant
  case voiceToRx
}
