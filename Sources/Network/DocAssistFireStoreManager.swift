//
//  DocAssistFireStoreManager.swift
//  DocAssist-ios
//
//  Created by Brunda B on 10/04/25.
//

import Foundation
import FirebaseFirestore

@MainActor
final class DocAssistFireStoreManager {

  static let shared = DocAssistFireStoreManager()

  private let databaseName = "doctool"
  private lazy var db: Firestore? = {
    Firestore.firestore(database: databaseName)
  }()

  private let docAssistCollectionName = "docassist"
  private let docIdCollectionName = "doctors"
  private let chatSessionsCollectionName = "context"
  private let sessionsCollectionName = "sessions"
  private let messagesCollectionName = "messages"

  func sendMessageToFirestore(businessId: String, doctorId: String, context: String, sessionId: String, messageId: Int, message: FirebaseMessageModel, completion: @escaping (String) -> Void) {

    let db = Firestore.firestore()
    var patientContext: String = ""
    
    if context != "General Chat" {
      patientContext = "in_patient"
    } else {
      patientContext = "out_of_patient"
    }
    
    let messageDocument = db
      .collection("docassist")
      .document(businessId)
      .collection("doctors")
      .document(doctorId)
      .collection("context")
      .document(context)
      .collection("sessions")
      .document(sessionId)
      .collection("messages")
      .document("\(messageId)")

    let data: [String: Any] = [
      "text": message.message,
      "sessionId": message.sessionId,
      "doctorId": message.doctorId,
      "patientId": message.patientId,
      "status": message.status,
      "role": message.role,
      "vaultFiles": message.vaultFiles,
      "userAgent": message.userAgent,
      "sessionIdentity": message.sessionIdentity,
      "ownerId": message.ownerId,
      "createdAt": message.createdAt,
      "chatContext": patientContext,
      "timestamp": message.timeStamp
    ]
    
    print("#BB \(messageDocument.path)")
    
    messageDocument.setData(data) { error in
      if let error = error {
        print("Error writing message to Firestore: \(error.localizedDescription)")
        completion("Error received")
      } else {
        print("Message successfully sent to Firestore!")
        completion("Successfully set the value")
      }
    }
  }
}
