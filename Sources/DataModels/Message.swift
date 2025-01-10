//
//  Message.swift
//  Chatbot
//
//  Created by Brunda B on 14/11/24.
//

import Foundation

struct Message: Decodable {
  let text: String
  let msgId: Int
  let overwrite: Bool
  var eof: Bool? = true
  
  enum CodingKeys: String, CodingKey {
    case text = "text"
    case msgId = "msg_id"
    case overwrite = "overwrite"
    case eof = "eof"
  }
}

struct MessageForFireStore {
  let text: String
  let msgId: Int
  let overwrite: Bool
  var eof: Bool
}
