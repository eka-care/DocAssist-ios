//
//  WebSocketModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//

import Foundation


struct WebSocketModel: Codable {
  let eventType: EventType
  let ts: Int
  let id: String?
  let contentType: ContentType?
  let msg: String?
  let data: WebSocketData?
  
  enum CodingKeys: String, CodingKey {
    case eventType = "ev"
    case ts
    case id = "_id"
    case contentType = "ct"
    case msg
    case data
  }
  
  enum EventType: String, Codable {
    case chat
    case stream
    case eos
    case auth
    case conn
    case err
    case ping
    case pong
    case sync
  }
  
  enum ContentType: String, Codable {
    case text
    case audio
    case file
    case pill
    case multi
    case inlineText
    case doctorCard
    case tips
    case mobileVerification
    
    enum codingKeys: String, CodingKey {
      case text, audio, file, pill, multi, tips
      case inlineText = "inline_text"
      case doctorCard = "doctor_card"
      case mobileVerification = "mobile_verification"
    }
  }
}

struct WebSocketData: Codable {
    let audio: String?
    let text: String?
    let format: String?
    let toolUseId: String?
    let choices: [String]?
    let additionalOption: String?
    let fileExtension: String?

    enum CodingKeys: String, CodingKey {
        case audio
        case text
        case format
        case toolUseId = "tool_use_id"
        case choices
        case additionalOption = "additional_option"
        case fileExtension = "extension"
    }

    init(audio: String? = nil,
         text: String? = nil,
         format: String? = nil,
         toolUseId: String? = nil,
         choices: [String]? = nil,
         additionalOption: String? = nil,
         fileExtension: String? = nil) {
        self.audio = audio
        self.text = text
        self.format = format
        self.toolUseId = toolUseId
        self.choices = choices
        self.additionalOption = additionalOption
        self.fileExtension = fileExtension
    }
}
