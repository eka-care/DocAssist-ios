//
//  ChatViewModel.swift
//  Chatbot
//
//  Created by Brunda B on 12/11/24.
//

import Foundation
import SwiftData
import SwiftUI
import AVFAudio

public struct ExistingChatResponse {
  var chatExist: Bool
  var sessionId: [String]
}

@MainActor
final class ChatViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
  
  @Published var streamStarted: Bool = false
  @Published var isLoading: Bool = false
  @Published private(set) var vmssid: String = ""
  private var dataStorage: String = ""
  private var context: ModelContext
  private var delegate : ConvertVoiceToText? = nil
  private let networkCall = NetworkCall()
  
  @Published var isRecording = false
  @Published var currentRecording: URL?
  @Published var voiceText: String?
  @Published var voiceProcessing: Bool = false
  @Published var messageInput: Bool = true
  
  var audioRecorder: AVAudioRecorder?
  var audioPlayer: AVAudioPlayer?
  
  init(context: ModelContext, delegate: ConvertVoiceToText? = nil) {
    self.context = context
    DatabaseConfig.shared.modelContext = context
    self.delegate = delegate
  }
  
  func sendMessage(newMessage: String?, imageUrls: [URL]?, vaultFiles: [String]?) {
    addUserMessage(newMessage, imageUrls)
    startStreamingPostRequest(query: newMessage, vaultFiles: vaultFiles)
  }
  
  private func addUserMessage(_ query: String?, _ imageUrls: [URL]?) {
    let msgIddup = (DatabaseConfig.shared.getLastMessageIdUsingSessionId(sessionId: vmssid) ?? -1) + 1
    
    do {
      if let fetchedSeesion = try fetchSession(bySessionId: vmssid) {
        let userData = ChatMessageModel(
          msgId: msgIddup,
          role: .user,
          messageFiles: nil,
          messageText: query,
          htmlString: nil,
          createdAt: 0,
          sessionData: fetchedSeesion,
          imageUrls: imageUrls
        )
        fetchedSeesion.chatMessages.append(userData)
      }
    } catch {
      print("Unable to fetch data")
    }
    
    saveData()
    setThreadTitle(with: query ?? "New Chat")
  }
  
  func startStreamingPostRequest(query: String?, vaultFiles: [String]?) {
    streamStarted = true
    NwConfig.shared.queryParams["session_id"] = vmssid
    networkCall.startStreamingPostRequest(query: query, vault_files: vaultFiles, onStreamComplete: { [weak self] in
      Task { @MainActor in
        self?.streamStarted = false
      }
    }) { [weak self] result in
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
              print("#BB message is \(message)")
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
    let allMessage = try? DatabaseConfig.shared.modelContext.fetch(descriptor)
    
    if let existingItem = allMessage?.first(where: {
      $0.sessionData?.sessionId == vmssid &&
      $0.msgId == message.msgId
    }) {
      existingItem.messageText = message.text
      saveData()
      print("SESSION DATA SAVED")
    } else { 
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
    return try DatabaseConfig.shared.modelContext.fetch(descriptor).first
  }
  
  func isSessionsPresent(oid: String, userDocId: String, userBId: String) -> ExistingChatResponse {
    do {
      let sessions = try DatabaseConfig.shared.fetchSessionId(fromOid: oid, userDocId: userDocId, userBId: userBId, context: DatabaseConfig.shared.modelContext)
      if let sessions {
        if sessions.count > 0 {
          return .init(chatExist: true, sessionId: sessions)
        }
       else {
        return .init(chatExist: false, sessionId: [])
      }
    }
    } catch {
      print("Can't fetch the sessions")
    }
    return .init(chatExist: false, sessionId: [])
  }
  
  func createSession(subTitle: String?, oid: String = "", userDocId: String, userBId: String) -> String {
    let currentDate = Date()
    let context = DatabaseConfig.shared.modelContext
    let ssid = UUID().uuidString
    let createSessionModel = SessionDataModel(sessionId: ssid, createdAt: currentDate, lastUpdatedAt: currentDate, title: "New Session", subTitle: subTitle, oid: oid, userDocId: userDocId, userBId: userBId)
    context?.insert(createSessionModel)
    saveData()
    switchToSession(ssid)
    return ssid
  }
  
  func switchToSession(_ id: String) {
    vmssid = id
  }
  
  func setThreadTitle(with query: String) {
    DatabaseConfig.shared.SaveTitle(sessionId: self.vmssid, title: query)
  }
  
  func trimLeadingSpaces(from input: String) -> String {
    if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return ""
    }
    return input.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  func getFormatedDateToDDMMYYYY(date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) {
      let timeFormatter = DateFormatter()
      timeFormatter.dateFormat = "HH:mm a"
      return timeFormatter.string(from: date)
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    } else {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "dd/MM/yyyy"
      return dateFormatter.string(from: date)
    }
  }
  
  func onTapOfAudioButton() {
    guard let currentRecording = currentRecording else {
      return
    }
    voiceProcessing = true
    delegate?.convertVoiceToText(audioFileURL:  currentRecording, completion: { [weak self] text in
      guard let self = self else { return }
      self.voiceText = text
      self.voiceProcessing = false
      self.messageInput = true
    })
  }
}

extension ChatViewModel: AVAudioRecorderDelegate  {
  
  func startRecording() {
    let recordingSession = AVAudioSession.sharedInstance()
    do {
      try recordingSession.setCategory(.record, mode: .default)
      try recordingSession.setActive(true)
      
      let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let audioFilename = documentsPath.appendingPathComponent("\(Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss")).m4a")
      
      let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder?.delegate = self
      audioRecorder?.record()
      
      isRecording = true
      currentRecording = audioFilename
    } catch {
      print("Could not start recording: \(error)")
    }
  }
  
  func stopRecording() {
    guard isRecording, let recorder = audioRecorder else {
      print("No recording to stop.")
      return
    }
    recorder.stop()
    onTapOfAudioButton()
    isRecording = false
  }
}


extension Date {
  func toString(dateFormat format: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: self)
  }
}
