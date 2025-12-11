//
//  SessionValidResponseModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//

import Foundation

struct SessionValidResponseModel: Decodable {
  let sessionId, msg: String
  let sessionValidity: Int
  enum CodingKeys: String, CodingKey {
    case sessionId = "session_id"
    case msg
    case sessionValidity = "session_validity_s"
  }
}
