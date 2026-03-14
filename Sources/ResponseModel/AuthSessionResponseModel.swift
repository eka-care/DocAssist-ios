//
//  AuthSessionModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 07/11/25.
//

import Foundation

struct AuthSessionResponseModel: Codable {
  let sessionID, sessionToken: String
  let sessionValidityS: Int
  let userID: String?
  let initialMessage: InitialMessage?
  let warnings: [String]?

  enum CodingKeys: String, CodingKey {
    case sessionID = "session_id"
    case sessionToken = "session_token"
    case sessionValidityS = "session_validity_s"
    case userID = "user_id"
    case initialMessage = "initial_message"
    case warnings
  }
}

struct InitialMessage: Codable {
  let text: String
  let suggestions: [SessionSuggestion]?
}

struct SessionSuggestion: Codable {
  let label: String
  let value: String
  let response: String?
}
