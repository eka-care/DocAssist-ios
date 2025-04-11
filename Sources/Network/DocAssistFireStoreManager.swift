//
//  DocAssistFireStoreManager.swift
//  DocAssist-ios
//
//  Created by Brunda B on 10/04/25.
//

import Foundation
import FirebaseFirestore

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

  func sendMessageToFirestore(businessId: String, doctorId: String, context: Bool, sessionId: String, messageId: Int, message: FirebaseMessageModel, completion: @escaping (String) -> Void) {

   // let db = Firestore.firestore()
    var patientContext: String = ""
    patientContext = context ? "in_patient" : "out_of_patient"
    
//    let messageDocument = db?
//      .collection("docassist")
//      .document(businessId)
//      .collection("doctors")
//      .document(doctorId)
//      .collection("context")
//      .document("out_of_patient")
//      .collection("sessions")
//      .document(sessionId)
//      .collection("messages")
//      .document("\(messageId)")
    
    let baseRef = db?
      .collection("docassist")
      .document(businessId)
      .collection("doctors")
      .document(doctorId)
      .collection("context")
      .document(patientContext)
    
    let messageDocument: DocumentReference?
    if context { // in_patient
      messageDocument = baseRef?
        .collection("patients")
        .document("adfa")
        .collection("sessions")
        .document(sessionId)
        .collection("messages")
        .document("\(messageId)")
    } else { // out_of_patient
      messageDocument = baseRef?
        .collection("sessions")
        .document(sessionId)
        .collection("messages")
        .document("\(messageId)")
    }


    let data: [String: Any] = [
      "message": message.message,
      "session_id": message.sessionId,
      "doctor_oid": message.doctorId ?? "",
      "patient_oid": message.patientId ?? "",
      "status": message.status,
      "role": message.role,
      "vault_files": message.vaultFiles,
      "user_agent": message.userAgent,
      "session_identity": message.sessionIdentity,
      "owner_id": message.ownerId,
      "created_at": message.createdAt,
      "chat_context": "",
      "timestamp": message.timeStamp
    ]
    
    print("#BB \(messageDocument?.path)")
    
    messageDocument?.setData(data) { error in
      if let error = error {
        print("#BB Error writing message to Firestore: \(error.localizedDescription)")
        completion("Error received")
      } else {
        print("#BB Message successfully sent to Firestore!")
        completion("#BB Successfully set the value")
      }
    }
  }
  
  func listenToFirestor() {
    
  }
}
