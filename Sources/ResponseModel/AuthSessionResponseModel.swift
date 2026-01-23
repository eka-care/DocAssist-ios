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
  
  enum CodingKeys: String, CodingKey {
    case sessionID = "session_id"
    case sessionToken = "session_token"
    case sessionValidityS = "session_validity_s"
  }
}
