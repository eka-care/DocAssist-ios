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
    let toolUse: Bool?
    let toolResult: String?
    let suggestions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case text = "text"
        case msgId = "msg_id"
        case overwrite = "overwrite"
        case toolUse = "tool_use"
        case toolResult = "tool_result"
        case suggestions
    }
}
