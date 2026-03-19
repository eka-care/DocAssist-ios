//
//  AuthSessionResponseModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 28/01/26.
//

import Foundation

struct AuthSessionResponseModel: Codable {
  let sessionID, sessionToken: String
  let sessionValidityS: Int
  let initialMessage: InitialMessage?
  
  enum CodingKeys: String, CodingKey {
    case sessionID = "session_id"
    case sessionToken = "session_token"
    case sessionValidityS = "session_validity_s"
    case initialMessage = "initial_message"
  }
}

struct InitialMessage: Codable {
  let text: String?
  let suggestions: [String]?
}
