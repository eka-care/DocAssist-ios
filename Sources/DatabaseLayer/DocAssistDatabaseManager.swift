//
//  DocAssistDatabaseManager.swift
//  ChatBotAiPackage
//
//  Created by Arya Vashisht on 14/02/25.
//

import CoreData

/**
 This file contains CRUD functions for the database layer.
 */

enum DocAssistDatabaseVersion {
  static let containerName = "DocAssistDataModel"
}

final class DocAssistDatabaseManager {
  
  // MARK: - Properties
  
  var container: NSPersistentContainer = {
    /// Loading model from package resources
    let bundle = Bundle.module
    let modelURL = bundle.url(forResource: DocAssistDatabaseVersion.containerName, withExtension: "mom")!
    let model = NSManagedObjectModel(contentsOf: modelURL)!
    let container = NSPersistentContainer(name: DocAssistDatabaseVersion.containerName, managedObjectModel: model)
    return container
  }()
  
  static let shared = DocAssistDatabaseManager()
  
  // MARK: - Init
  
  private init() {}
}

// MARK: - Create

extension DocAssistDatabaseManager {
  
  /// Create chat in the database
  /// - Parameters:
  ///   - text: text of the chat
  ///   - messageID: message id of the chat
  ///   - role: message role of the chat
  ///   - sessionID: session id of which the chat is a part of
  ///
  func createSession(sessionId: String, sessionToken: String, businessId: String, ownerId: String) {
     let date = Calendar.current
     let context = container.viewContext
    
    let session = DocAssistSessionData(context: context)
    session.sessionId = sessionId
  }
//  func createChat(
//    text: String,
//    messageID: Int,
//    role: ChatRole,
//    sessionID: String,
//    imageURIs: [String]
//  ) {
//    do {
//      /// Get session to which the chat belongs
//      let sessionData = try container.viewContext.fetch(
//        QueryHelper.fetchSession(sessionID: sessionID)
//      ).first
//      /// Create chat
//     let chat = ChatData(context: container.viewContext)
//      chat.text = text
//      chat.messageID = Int64(messageID)
//      chat.role = role.rawValue
//      chat.imageURIs = imageURIs
//      /// Attach chat to session data
//      sessionData?.addToToChatData(chat)
//    } catch {
//      debugPrint("Error creating chat: \(error.localizedDescription)")
//    }
//  }
//
//  /// Create session in the database
//  /// - Parameters:
//  ///   - bid: bid of the session
//  ///   - createdAt: createdAt of the session
//  ///   - filterId: filterId of the session
//  ///   - lastUpdatedAt: lastUpdatedAt of the session
//  ///   - ownerId: ownerId of the session
//  ///   - sessionID: sessionID of the session
//  ///   - subtitle: subtitle of the session
//  ///   - title: title of thes session
//  func createSession(
//    bid: String?,
//    createdAt: Date?,
//    filterId: String?,
//    lastUpdatedAt: Date?,
//    ownerId: String?,
//    sessionID: UUID?,
//    subtitle: String?,
//    title: String?
//  ) {
//    let session = SessionData(context: container.viewContext)
//    session.bid = bid
//    session.createdAt = createdAt
//    session.filterId = filterId
//    session.lastUpdatedAt = lastUpdatedAt
//    session.ownerId = ownerId
//    session.sessionID = sessionID
//    session.subtitle = subtitle
//    session.title = title
//    do {
//      try container.viewContext.save()
//    } catch {
//      debugPrint("Error saving session: \(error.localizedDescription)")
//    }
//  }
}

// MARK: - Update

extension DocAssistDatabaseManager {
  /// Used to update chat
  /// - Parameters:
  ///   - messageID: message id of the chat to be updated
  ///   - sessionID: session id of the chat to be updated
  ///   - messageText: text of the chat to be updated
//  func updateChat(
//    messageID: Int,
//    sessionID: String,
//    messageText: String? = nil
//  ) {
//    guard let fetchRequest = QueryHelper.fetchMessage(
//      messageID: messageID,
//      sessionID: sessionID,
//      context: container.viewContext
//    ) else { return }
//
//    do {
//      let chatResults = try container.viewContext.fetch(fetchRequest)
//      let chat = chatResults.first
//      chat?.text = messageText
//    } catch {
//      debugPrint("Error updating chat: \(error.localizedDescription)")
//    }
//  }
  
  /// Used to update chat
  /// - Parameters:
  ///   - objectID: object id of the chat
  ///   - text: text of the chat
//  func updateChat(
//    objectID: NSManagedObjectID,
//    text: String? = nil
//  ) {
//    do {
//      guard let chat = try container.viewContext.existingObject(with: objectID) as? ChatData else { return }
//      if let text {
//        chat.text = text
//      }
//      try container.viewContext.save()
//    } catch {
//      debugPrint("Error updating chat: \(error.localizedDescription)")
//    }
//  }
  
  func updateSession() {}
}

// MARK: - Read

extension DocAssistDatabaseManager {
//  func fetchChats(fetchRequest: NSFetchRequest<ChatData>) -> [ChatData] {
//    do {
//      let chatResults = try container.viewContext.fetch(fetchRequest)
//      return chatResults
//    } catch {
//      debugPrint("Error fetching chats: \(error.localizedDescription)")
//    }
//    return []
//  }
//
//  func fetchSessions(fetchRequest: NSFetchRequest<SessionData>) -> [SessionData] {
//    do {
//      let sessionResults = try container.viewContext.fetch(fetchRequest)
//      return sessionResults
//    } catch {
//      debugPrint("Error fetching chats: \(error.localizedDescription)")
//    }
//    return []
//  }
}

// MARK: - Delete

extension DocAssistDatabaseManager {
  func deleteChat() {
    
  }
  
  func deleteSession() {
    
  }
}

