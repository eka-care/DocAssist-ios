//
//  SessionValidResponseModel.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 10/11/25.
//

import Foundation

struct SessionValidResponseModel: Codable {
    let sessionID: String
    let sessionValidityS: Int
    let sessionData: SessionData
    let userID, msg: String

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case sessionValidityS = "session_validity_s"
        case sessionData = "session_data"
        case userID = "user_id"
        case msg
    }
}

struct SessionData: Codable {
    let sessionID, wid, agentID, sessionToken: String
    let exp: Int
    let referer: String
    let rno: Int
    let userid: String
    let ttl: Int

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case wid
        case agentID = "agent_id"
        case sessionToken = "session_token"
        case exp, referer, rno, userid, ttl
    }
}
