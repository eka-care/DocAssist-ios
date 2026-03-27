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
    case inlineText

    enum CodingKeys: String, CodingKey {
      case text, audio, file, tips, tool
      case audioTranscript = "audio_transcript"
      case toolStart = "tool_start"
      case toolEnd = "tool_end"
      case inlineText = "inline_text"
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      let rawValue = try container.decode(String.self)
      switch rawValue {
      case "text": self = .text
      case "audio": self = .audio
      case "file": self = .file
      case "tool": self = .tool
      case "tips": self = .tips
      case "audio_transcript": self = .audioTranscript
      case "tool_start": self = .toolStart
      case "tool_end": self = .toolEnd
      case "inline_text": self = .inlineText
      default: self = .text
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .text: try container.encode("text")
      case .audio: try container.encode("audio")
      case .file: try container.encode("file")
      case .tool: try container.encode("tool")
      case .tips: try container.encode("tips")
      case .audioTranscript: try container.encode("audio_transcript")
      case .toolStart: try container.encode("tool_start")
      case .toolEnd: try container.encode("tool_end")
      case .inlineText: try container.encode("inline_text")
      }
    }
  }
}

struct FileUploadURL: Codable {
  let id: String
  let url: String
}

struct WebSocketData: Codable {
  let audio: String?
  let text: String?
  let format: String?
  let toolType, toolID, toolName: String?
  let details: Details?
  let urls: [FileUploadURL]?
  let url: String?
  let additionalOption: String?
  let fileExtension: String?

  enum CodingKeys: String, CodingKey {
    case audio
    case text
    case format
    case additionalOption = "additional_option"
    case fileExtension = "extension"
    case toolType = "tool_type"
    case toolID = "tool_id"
    case toolName = "tool_name"
    case details, urls, url
  }

  init(audio: String? = nil, text: String? = nil, format: String? = nil, toolType: String? = nil, toolID: String? = nil, toolName: String? = nil, details: Details? = nil, urls: [FileUploadURL]? = nil, url: String? = nil, additionalOption: String? = nil, fileExtension: String? = nil) {
    self.audio = audio
    self.text = text
    self.format = format
    self.toolType = toolType
    self.toolID = toolID
    self.toolName = toolName
    self.details = details
    self.urls = urls
    self.url = url
    self.additionalOption = additionalOption
    self.fileExtension = fileExtension
  }
}

// MARK: - Details
struct Details: Codable {
  let component: String
  let input: Input
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

