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

@MainActor
final class ChatViewModel: NSObject, ObservableObject, URLSessionDataDelegate {
  private var context: ModelContext
  @Published var streamStarted: Bool = false
  private var delegate : ConvertVoiceToText? = nil
  @Published var isLoading: Bool = false
  @Published var vmssid: String = ""
  private var dataStorage: String = ""
  private let networkCall = NetworkCall()
  
  @Published var isRecording = false
  @Published var currentRecording: URL?
  @Published var voiceText: String?
  
  var audioRecorder: AVAudioRecorder?
  var audioPlayer: AVAudioPlayer?
  
  init(context: ModelContext, delegate: ConvertVoiceToText? = nil) {
    self.context = context
    DatabaseConfig.shared.modelContext = context
    self.delegate = delegate
  }
  
  func sendMessage(newMessage: String) {
    addUserMessage(newMessage)
    startStreamingPostRequest(query: newMessage)
  }
  
  private func addUserMessage(_ query: String) {
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
    streamStarted = true
    NwConfig.shared.queryParams["session_id"] = vmssid
    networkCall.startStreamingPostRequest(query: query, onStreamComplete: { [weak self] in
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
              print("Message: \(message.text)")
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
    let allMessage = try? DatabaseConfig.shared.modelContext.fetch(descriptor)
    
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
    return try DatabaseConfig.shared.modelContext.fetch(descriptor).first
  }
  
  func createSession(subTitle: String?, oid: String = "") -> String {
      let currentDate = Date()
      let context = DatabaseConfig.shared.modelContext
      if !oid.isEmpty {
          do {
            if let existingSessionId = try fetchSessionId(fromOid: oid, context: DatabaseConfig.shared.modelContext) {
              switchToSession(existingSessionId)
                  return existingSessionId
              }
          } catch {
              print("Error fetching session for oid: \(error)")
          }
      }

      let ssid = UUID().uuidString
    let createSessionModel = SessionDataModel(sessionId: ssid, createdAt: currentDate, lastUpdatedAt: currentDate, title: "New Session", subTitle: subTitle, oid: oid)
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
  
  func onTapOfAudioButton(){
    guard let currentRecording = currentRecording else {
      return
    }
    delegate?.convertVoiceToText(audioFileURL:  currentRecording, completion: { [weak self] text in
      guard let self = self else { return }
      voiceText = text
    })
  }
}

func fetchSessionId(fromOid oid: String, context: ModelContext) throws -> String? {

    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
        predicate: #Predicate { $0.oid == oid }
    )
    let results = try context.fetch(fetchDescriptor)
    return results.first?.sessionId
}
 
func fetchPatientName (fromSessionId ssid: String, context: ModelContext) throws -> String {

    let fetchDescriptor = FetchDescriptor<SessionDataModel>(
      predicate: #Predicate { $0.sessionId == ssid }
    )
  let results = try context.fetch(fetchDescriptor)
    return results.first?.subTitle ?? ""
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
