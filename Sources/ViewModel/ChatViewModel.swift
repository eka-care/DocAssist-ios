//
//  ChatViewModel.swift
//  Chatbot
//
//  Created by Brunda B on 12/11/24.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ChatViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
  private var context: ModelContext
  
  init(context: ModelContext) {
    self.context = context
  }
  
  @Published var isLoading: Bool = false
  @Published var vmssid: String = ""
  private var dataStorage: String = ""
  private let networkCall = NetworkCall()
  
  func sendMessage(newMessage: String) {
    addUserMessage(newMessage)
    startStreamingPostRequest(query: newMessage)
  }
  
  private func addUserMessage(_ query: String) {
    let msgIddup = (QueueConfigRepo1.shared.getLastMessageIdUsingSessionId(sessionId: vmssid) ?? -1) + 1
    
    do {
      if let fetchedSeesion = try fetchSession(bySessionId: vmssid) {
        let userData = ChatMessageModel(
          msgId: msgIddup,
          role: .user,
          messageFiles: nil,
          messageText: query,
          htmlString: nil,
          createdAt: 0,
          sessionData: fetchedSeesion
        )
        fetchedSeesion.chatMessages.append(userData)
      }
    } catch {
      print("Unable to fetch data")
    }
    
    saveData()
    setThreadTitle(with: query)
  }
  
  func startStreamingPostRequest(query: String) {
    NwConfig.shared.queryParams["session_id"] = vmssid
    networkCall.startStreamingPostRequest(query: query) { [weak self] result in
          switch result {
          case .success(let responseString):
            Task {
              await self?.handleStreamResponse(responseString)
            }
          case .failure(let error):
            print("Error streaming: \(error)")
          }
        }

  }
  
  func handleStreamResponse(_ responseString: String) {
    let splitLines = responseString.split(separator: "\n")
    
    for line in splitLines {
      if line.contains("data:") {
        let jsonRange = line.range(of: "{")
        if let jsonRange = jsonRange {
          let jsonString = String(line[jsonRange.lowerBound...])
          if let jsonData = jsonString.data(using: .utf8) {
            do {
              let message = try JSONDecoder().decode(Message.self, from: jsonData)
              self.updateMessage(with: message)
            } catch {
              print("Failed to decode JSON: \(error.localizedDescription)")
            }
          }
        }
      }
    }
  }
  
  private func updateMessage(with message: Message) {
    let descriptor = FetchDescriptor<ChatMessageModel>()
    let allMessage = try? QueueConfigRepo1.shared.modelContext.fetch(descriptor)
    
    if let existingItem = allMessage?.first(where: {
      $0.sessionData?.sessionId == vmssid &&
      $0.msgId == message.msgId
    }) {
      existingItem.messageText = message.text
      saveData()
      print("SESSION DATA SAVED")
    } else { /// Else we create a new entry in db
      createNewChatMessage(from: message)
    }
  }
  
  
  private func createNewChatMessage(from message: Message) {
    do {
      if let fetchedSeesion = try fetchSession(bySessionId: vmssid) {
        let chat = ChatMessageModel(
          msgId: message.msgId,
          role: .Bot,
          messageFiles: nil,
          messageText: message.text,
          htmlString: nil,
          createdAt: 0,
          sessionData: fetchedSeesion
        )
        fetchedSeesion.chatMessages.append(chat)
        saveData()
      }
    } catch {
      print("Unable to create new chat")
    }
  }
  
  private func saveData() {
    do {
      try context.save()
    } catch {
      print("Error saving data: \(error)")
    }
  }
  
  func fetchSession(bySessionId sessionId: String) throws -> SessionDataModel? {
    let descriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate<SessionDataModel> { session in
        session.sessionId == sessionId
      }
    )
    return try QueueConfigRepo1.shared.modelContext.fetch(descriptor).first
  }
  
  func createSession(subTitle: String?) {
    let currentDate = Date()
    let ssid = UUID().uuidString
    let createSessionModel = SessionDataModel(sessionId: ssid, createdAt: currentDate, lastUpdatedAt: currentDate, title: "New Session", subTitle: subTitle)
    context.insert(createSessionModel)
    
    saveData()
    switchToSession(ssid)
  }
  
  private func switchToSession(_ id: String) {
    vmssid = id
  }
  
  func setThreadTitle(with query: String) {
    QueueConfigRepo1.shared.SaveTitle(sessionId: self.vmssid, title: query)
  }
  
  func trimLeadingSpaces(from input: String) -> String {
    if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return ""
    }
    return input.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  func getFormatedDateToDDMMYYYY(date: Date) -> String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "dd/MM/yyyy"
      return dateFormatter.string(from: date)
  }
}
