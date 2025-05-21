//
//  FirestoreMessageModel.swift
//  DocAssist-ios
//
//  Created by Brunda B on 10/04/25.
//

import Foundation

struct FirestoreMessageModel: Codable {
    var message: String = ""
    var sessionId: String
    var doctorId: String? = nil
    var patientId: String? = nil
    var status: String? = nil
    var role: String? = nil
    var vaultFiles: [String]? = nil
    var userAgent: String = ""
    var sessionIdentity: String? = ""
    var ownerId: String? = ""
    var createdAt: Int64 = 0
    var chatContext: String? = ""
    var timeStamp: Int64 = 0

    enum CodingKeys: String, CodingKey {
        case message
        case sessionId = "session_id"
        case doctorId = "doctor_oid"
        case patientId = "patient_oid"
        case status
        case role
        case vaultFiles = "vault_files"
        case userAgent = "user_agent"
        case sessionIdentity = "session_identity"
        case ownerId = "owner_id"
        case createdAt = "created_at"
        case chatContext = "chat_context"
        case timeStamp = "timestamp"
    }
}
