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
  
  // MARK: - Helper Methods
  
  /// Gets the context string based on the boolean flag
  private func getContextString(context: Bool) -> String {
    return context ? "in_patient" : "out_of_patient"
  }
  
  /// Creates the base reference for all operations
  private func getBaseReference(businessId: String, doctorId: String, context: Bool) -> DocumentReference? {
    return db?
      .collection(docAssistCollectionName)
      .document(businessId)
      .collection(docIdCollectionName)
      .document(doctorId)
      .collection(chatSessionsCollectionName)
      .document(getContextString(context: context))
  }
  
  /// Creates the reference to a specific message document
  private func getMessageReference(businessId: String, doctorId: String, sessionId: String,
                                   context: Bool, patientId: String, messageId: Int) -> DocumentReference? {
    let baseRef = getBaseReference(businessId: businessId, doctorId: doctorId, context: context)
    
    if context {
      return baseRef?
        .collection("patients")
        .document(patientId)
        .collection(sessionsCollectionName)
        .document(sessionId)
        .collection(messagesCollectionName)
        .document("\(messageId)")
    } else {
      return baseRef?
        .collection(sessionsCollectionName)
        .document(sessionId)
        .collection(messagesCollectionName)
        .document("\(messageId)")
    }
  }

  // MARK: - Public Methods
  
  func sendMessageToFirestore(
    businessId: String,
    doctorId: String,
    context: Bool,
    sessionId: String,
    messageId: Int,
    message: FirestoreMessageModel,
    completion: @escaping (
      String
    ) -> Void
  ) {
    
    let messageDocument = getMessageReference(
      businessId: businessId,
      doctorId: doctorId,
      sessionId: sessionId,
      context: context,
      patientId: message.patientId ?? "",
      messageId: messageId
    )

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
        completion("#BB Successfully set the value")
      }
    }
  }
  
  func listenToFirestoreMessages(
    businessId: String,
    doctorId: String,
    sessionId: String,
    context: Bool = false,
    patientId: String = "",
    messageId: Int,
    completion: @escaping (
      [String: Any]
    ) -> Void
  ) {
    
    let messagesRef = getMessageReference(
      businessId: businessId,
      doctorId: doctorId,
      sessionId: sessionId,
      context: context,
      patientId: patientId,
      messageId: messageId
    )
    
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
  
  func updateFireStore(
    key: String,
    with: Bool,
    businessId: String,
    doctorId: String,
    sessionId: String,
    context: Bool = false,
    patientId: String = "",
    messageId: Int
  ) {
    
    let messagesRef = getMessageReference(
      businessId: businessId,
      doctorId: doctorId,
      sessionId: sessionId,
      context: context,
      patientId: patientId,
      messageId: messageId
    )
    
    print("#BB path is \(messagesRef?.path)")
    
    messagesRef?.setData([key: with]) { error in
      if let error = error {
        print("#BB Error updating Firestore: \(error.localizedDescription)")
      }
      print("#BB Successfully updated Firestore")
    }
  }
  
  func syncAllMessages(
    businessId: String,
    doctorId: String,
    completion: @escaping ([FireStoreChatResponse]) -> Void
  ) {
    let outPatientRef = getBaseReference(businessId: businessId, doctorId: doctorId, context: false)
    let inPatientRef = getBaseReference(businessId: businessId, doctorId: doctorId, context: true)
    var allMessages: [FireStoreChatResponse] = []
    
    
    print("#BB Out-patient path: \(outPatientRef?.path ?? "nil")")
    print("#BB In-patient path: \(inPatientRef?.path ?? "nil")")
    
    print("#BB Starting sync...")
    
    // Fetch out-patient messages
    outPatientRef?
      .collection(sessionsCollectionName)
      .getDocuments { snapshot, error in
        if let error = error {
          print("#BB Error fetching out-patient sessions: \(error.localizedDescription)")
          return
        }
        
        guard let sessions = snapshot?.documents else {
          print("#BB No out-patient sessions found")
          return
        }
        
        print("#BB Found \(sessions.count) out-patient sessions")
        
        for session in sessions {
          let sessionId = session.documentID
          print("#BB Processing session: \(sessionId)")
          
          outPatientRef?
            .collection(self.sessionsCollectionName)
            .document(sessionId)
            .collection(self.messagesCollectionName)
            .getDocuments { messagesSnapshot, messagesError in
              if let error = messagesError {
                print("#BB Error fetching messages: \(error.localizedDescription)")
                return
              }
              
              if let messages = messagesSnapshot?.documents {
                print("#BB Found \(messages.count) messages in session \(sessionId)")
                
                for messageDoc in messages {
                  let data = messageDoc.data()
                  do {
                    let jsonData = try JSONSerialization.data(withJSONObject: data)
                    let messageResponse = try JSONDecoder().decode(FireStoreChatResponse.self, from: jsonData)
                    allMessages.append(messageResponse)
                    print("#BB Successfully decoded message")
                  } catch {
                    print("#BB Error decoding message: \(error.localizedDescription)")
                    print("#BB Data: \(data)")
                  }
                }
                
                completion(allMessages)
              }
            }
        }
      }
  }
}
