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
    case tool
    case tips
    case audioTranscript
    case toolStart
    case toolEnd
    
    enum codingKeys: String, CodingKey {
      case text, audio, file, tips, tool
      case audioTranscript = "audio_transcript"
      case toolStart = "tool_start"
      case toolEnd = "tool_end"
    }
  }
}

struct WebSocketData: Codable {
  let audio: String?
  let text: String?
  let format: String?
  let toolType, toolID, toolName: String?
  let details: Details?
  let urls: [URLElement]?
  let additionalOption: String?
  let fileExtension: String?
  let extensions: [String]?   // used when requesting a file upload slot
  let meta: ToolMeta?

  enum CodingKeys: String, CodingKey {
    case audio
    case text
    case format
    case additionalOption = "additional_option"
    case fileExtension = "extension"
    case extensions
    case toolType = "tool_type"
    case toolID = "tool_id"
    case toolName = "tool_name"
    case details, urls, meta
  }

  init(
    audio: String? = nil,
    text: String? = nil,
    format: String? = nil,
    toolType: String? = nil,
    toolID: String? = nil,
    toolName: String? = nil,
    details: Details? = nil,
    urls: [URLElement]? = nil,
    additionalOption: String? = nil,
    fileExtension: String? = nil,
    extensions: [String]? = nil,
    meta: ToolMeta? = nil
  ) {
    self.audio = audio
    self.text = text
    self.format = format
    self.toolType = toolType
    self.toolID = toolID
    self.toolName = toolName
    self.details = details
    self.urls = urls
    self.additionalOption = additionalOption
    self.fileExtension = fileExtension
    self.extensions = extensions
    self.meta = meta
  }
}

// MARK: - ToolMeta
struct ToolMeta: Codable {
  let toolClass: String?

  enum CodingKeys: String, CodingKey {
    case toolClass = "tool_class"
  }
}

// MARK: - Details
struct Details: Codable {
  let status: ToolStatus?
  let component: ComponentType
  let input: Input

  enum ToolStatus: String, Codable {
    case progress
    case failure
    case success
  }

  enum ComponentType: String, Codable {
    case pills
    case multi
  }
}

// MARK: - Input
struct Input: Codable {
  let text: String
  let options: [Option]
}

// MARK: - Option
struct Option: Codable {
  let label, value: String
}

// MARK: - URLElement
struct URLElement: Codable {
  let id, url: String
}
