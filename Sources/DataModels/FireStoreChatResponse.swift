//
//  FireStoreChatResponse.swift
//  DocAssist-ios
//
//  Created by Brunda B on 18/04/25.
//

import Foundation

struct FireStoreChatResponse: Codable {
  let businessID, chatContext: String?
  let createdAt: Int?
  let doctorOID: String?
  let isEOF: Bool?
  let message, ownerID, patientOID, role: String?
  let sessionID, sessionIdentity, status: String?
  let suggestions: [String]?
  let timestamp: Int?
  let userAgent: String?
  let vaultFiles: [String]?
  
  enum CodingKeys: String, CodingKey {
    case businessID = "business_id"
    case chatContext = "chat_context"
    case createdAt = "created_at"
    case doctorOID = "doctor_oid"
    case isEOF = "is_eof"
    case message
    case ownerID = "owner_id"
    case patientOID = "patient_oid"
    case role
    case sessionID = "session_id"
    case sessionIdentity = "session_identity"
    case status, suggestions, timestamp
    case userAgent = "user_agent"
    case vaultFiles = "vault_files"
  }
}
