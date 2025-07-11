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

  func sendMessageToFirestore(businessId: String, doctorId: String, context: Bool, sessionId: String, messageId: Int, message: FirestoreMessageModel, completion: @escaping (String) -> Void) {
    
    var patientContext: String = ""
    patientContext = context ? "in_patient" : "out_of_patient"
    
    let baseRef = db?
      .collection(docAssistCollectionName)
      .document(businessId)
      .collection(docIdCollectionName)
      .document(doctorId)
      .collection(chatSessionsCollectionName)
      .document(patientContext)
    
    let messageDocument: DocumentReference?
    /// patinet context
    if context {
      messageDocument = baseRef?
        .collection("patients")
        .document(message.patientId ?? "")
        .collection(sessionsCollectionName)
        .document(sessionId)
        .collection(messagesCollectionName)
        .document("\(messageId)")
      /// out of patient context
    } else {
      messageDocument = baseRef?
        .collection(sessionsCollectionName)
        .document(sessionId)
        .collection(messagesCollectionName)
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
    
    messageDocument?.setData(data) { error in
      if let error = error {
        print("#BB Error writing message to Firestore: \(error.localizedDescription)")
        completion("Error received")
      } else {
        completion("#BB Successfully set the value")
      }
    }
  }
  
  func listenToFirestoreMessages(businessId: String, doctorId: String, sessionId: String, context: Bool = false, patientId: String = "", messageId: Int, completion: @escaping ([String: Any]) -> Void) {
    var patientContext = context ? "in_patient" : "out_of_patient"
    let baseRef = db?
      .collection(docAssistCollectionName)
      .document(businessId)
      .collection(docIdCollectionName)
      .document(doctorId)
      .collection(chatSessionsCollectionName)
      .document(patientContext)
    
    let messagesRef: DocumentReference?
    if context {
      messagesRef = baseRef?
        .collection("patients")
        .document(patientId)
        .collection(sessionsCollectionName)
        .document(sessionId)
        .collection(messagesCollectionName)
        .document("\(messageId)")  // Document reference for messageId
    } else {
      messagesRef = baseRef?
        .collection(sessionsCollectionName)
        .document(sessionId)
        .collection(messagesCollectionName)
        .document("\(messageId)")  // Document reference for messageId
    }
    print("#BB path is \(messagesRef?.path)")
    
    messagesRef?.addSnapshotListener { snapshot, error in
      if let error = error {
        print("#BB Firestore listen error: \(error.localizedDescription)")
        return
      }
      
      guard let document = snapshot else {
        print("#BB Snapshot was nil")
        return
      }
      
      if !document.exists {
        print("#BB Document does not exist at path: \(document.reference.path)")
        return
      }
      
      if let data = document.data(), !data.isEmpty {
        completion(data)
      } else {
        print("#BB Document exists but data was empty at path: \(document.reference.path)")
      }
    }
  }
}
