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
    let chunkId: Int
    let overwrite: Bool
    let suggestions: [String]?
    
    enum CodingKeys: String, CodingKey {
        case text = "text"
        case msgId = "msg_id"
        case chunkId = "chunk_id"
        case overwrite = "overwrite"
        case suggestions
    }
}
