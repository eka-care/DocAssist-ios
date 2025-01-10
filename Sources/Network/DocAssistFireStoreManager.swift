//
//  DocAssistFireStoreManager.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 09/01/25.
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
  private let chatSessionsCollectionName = "chat_sessions"
  private let sessionsCollectionName = "sessions"
  private let messagesCollectionName = "messages"
  
  func sendMessageToFirestore(docAssistId: String, doctorId: String, chatSessionId: String, sessionId: String, messageId: Int, message: Message, completion: @escaping (String) -> Void) {
    
    let db = Firestore.firestore()
    
    let messageDocument = db
      .collection("docassist")
      .document(docAssistId)
      .collection("doctors")
      .document(doctorId)
      .collection("chat_sessions")
      .document(chatSessionId)
      .collection("sessions")
      .document(sessionId)
      .collection("messages")
      .document("\(messageId)")
    
    let data: [String: Any] = [
      "text": message.text,
      "msgId": message.msgId
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
  
  func startListeningForMessages(docAssistId: String, doctorId: String, chatSessionId: String, sessionId: String, onUpdate: @escaping ([MessageForFireStore]) -> Void) {
    let db = Firestore.firestore()
    db.collection("docassist")
      .document(docAssistId)
      .collection("doctors")
      .document(doctorId)
      .collection("chat_sessions")
      .document(chatSessionId)
      .collection("sessions")
      .document(sessionId)
      .collection("messages")
      .addSnapshotListener { snapshot, error in
        if let error = error {
          print("Error listening for messages: \(error.localizedDescription)")
          return
        }
        
        guard let documents = snapshot?.documents else {
          print("No messages found")
          return
        }
        
        let messages = documents.compactMap { doc -> MessageForFireStore? in
          let data = doc.data()
          guard let text = data["text"] as? String,
                let msgId = data["msgId"] as? Int,
                let overwrite = data["overwrite"] as? Bool,
                let eof = data["eof"] as? Bool else {
            return nil
          }
          return MessageForFireStore(text: text, msgId: msgId, overwrite: overwrite, eof: eof)
        }
        onUpdate(messages)
      }
  }
}
