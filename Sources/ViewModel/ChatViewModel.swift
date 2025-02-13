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
import AVFoundation

public struct ExistingChatResponse {
  var chatExist: Bool
  var sessionId: [String]
}

@Observable
public final class ChatViewModel: NSObject, URLSessionDataDelegate {
  
  var streamStarted: Bool = false
  private(set) var vmssid: String = ""
  private var context: ModelContext
  private var delegate : ConvertVoiceToText? = nil
  private let networkCall = NetworkCall()
  var inputString = ""
  var isRecording = false
  var currentRecording: URL?
  var voiceProcessing: Bool = false
  var messageInput: Bool = true
  var showPermissionAlert = false
  var alertTitle = ""
  var alertMessage = ""
  var audioRecorder: AVAudioRecorder?
  var audioPlayer: AVAudioPlayer?
  
  var showPermissionAlertBinding: Binding<Bool> {
    Binding { [weak self] in
      self?.showPermissionAlert ?? false
    } set: { [weak self] newValue in
      self?.showPermissionAlert = newValue
    }
  }
  
  var inputStringBinding: Binding<String> {
    Binding { [weak self] in
      self?.inputString ?? ""
    } set: { [weak self] newValue in
      self?.inputString = newValue
    }
  }
  
  init(context: ModelContext, delegate: ConvertVoiceToText? = nil) {
    self.context = context
    self.delegate = delegate
  }
  
  func sendMessage(newMessage: String?, imageUrls: [String]?, vaultFiles: [String]?, sessionId: String) async {
    await addUserMessage(newMessage, imageUrls, sessionId)
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      print("#BB sessionId is \(sessionId)")
      startStreamingPostRequest(query: newMessage, vaultFiles: vaultFiles, sessionId: sessionId)
    }
  }
  
  private func addUserMessage(_ query: String?, _ imageUrls: [String]?, _ sessionId: String) async {
    let msgIddup = await (DatabaseConfig.shared.getLastMessageIdUsingSessionId(sessionId: vmssid) ?? -1) + 1
    
    do {
      if let fetchedSeesion = try await DatabaseConfig.shared.fetchSession(bySessionId: sessionId) {
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
    
    await DatabaseConfig.shared.saveData()
    await setThreadTitle(with: query ?? "New Chat")
  }
  
  func startStreamingPostRequest(query: String?, vaultFiles: [String]?, sessionId: String) {
    streamStarted = true
    NwConfig.shared.queryParams["session_id"] = sessionId
    networkCall.startStreamingPostRequest(query: query, vault_files: vaultFiles, onStreamComplete: {
      self.streamStarted = false
    }) { [weak self] result in
      switch result {
      case .success(let responseString):
        Task {
          await self?.handleStreamResponse(responseString, sessionId)
        }
      case .failure(let error):
        print("Error streaming: \(error)")
      }
    }
  }
  
  func handleStreamResponse(_ responseString: String,_ sessionId: String) async {
    let splitLines = responseString.split(separator: "\n")
    
    for line in splitLines {
      if line.contains("data:") {
        let jsonRange = line.range(of: "{")
        if let jsonRange = jsonRange {
          let jsonString = String(line[jsonRange.lowerBound...])
          if let jsonData = jsonString.data(using: .utf8) {
            do {
              let message = try JSONDecoder().decode(Message.self, from: jsonData)
              await updateMessage(with: message, sessionId: sessionId)
            } catch {
              print("Failed to decode JSON: \(error.localizedDescription)")
            }
          }
        }
      }
    }
  }
  
  private func updateMessage(with message: Message, sessionId: String) async {
   
    let allMessage = await DatabaseConfig.shared.fetchAllChatMessageFromSession(session: sessionId)
    
    if let existingItem = allMessage.first(where: {
      $0.msgId == message.msgId
    }) {
      DispatchQueue.main.async {
        existingItem.messageText = message.text
        DatabaseConfig.shared.saveData()
      }
    } else {
        await createNewChatMessage(from: message, sessionId: sessionId)
    }
  }
  
  private func createNewChatMessage(from message: Message, sessionId: String) async {
    if let fetchedSeesion = try? await DatabaseConfig.shared.fetchSession(bySessionId: sessionId) {
      let chat = ChatMessageModel(
        msgId: message.msgId,
        role: .Bot,
        messageFiles: nil,
        messageText: message.text,
        htmlString: nil,
        createdAt: 0,
        sessionData: fetchedSeesion
      )
      DispatchQueue.main.async {
        fetchedSeesion.chatMessages.append(chat)
      }
      await DatabaseConfig.shared.saveData()
    }
  }
  
  func isSessionsPresent(oid: String, userDocId: String, userBId: String) async -> Bool {
    do {
      let sessions = try await DatabaseConfig.shared.fetchSessionId(fromOid: oid, userDocId: userDocId, userBId: userBId)
      
      if sessions.filter({ !$0.chatMessages.isEmpty }).count > 0 {
        return true
      } else {
        return false
      }
    } catch {
      print("Can't fetch the sessions")
    }
    return false
  }
  
  func createSession(subTitle: String?, oid: String = "", userDocId: String, userBId: String) async -> String {
    let currentDate = Date()
    let ssid = UUID().uuidString
    print("#BB session Id in viewModel is \(ssid)")
    let createSessionModel = SessionDataModel(sessionId: ssid, createdAt: currentDate, lastUpdatedAt: currentDate, title: "New Session", subTitle: subTitle, oid: oid, userDocId: userDocId, userBId: userBId)
    await DatabaseConfig.shared.insertSession(session: createSessionModel)
    await DatabaseConfig.shared.saveData()
    switchToSession(ssid)
    return ssid
  }
  
  func switchToSession(_ id: String) {
    vmssid = id
  }
  
  func setThreadTitle(with query: String) async {
    await DatabaseConfig.shared.SaveTitle(sessionId: self.vmssid, title: query)
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
      self.inputString = text
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
  
  func dontRecord() {
    messageInput = true
  }
  
  func handleMicrophoneTap() {
    let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    
    switch micStatus {
    case .authorized:
      messageInput = false
      startRecording()
      
    case .denied:
      alertTitle = "Microphone Access Denied"
      alertMessage = "To record audio, please enable microphone access in Settings."
      showPermissionAlert = true
      
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
        DispatchQueue.main.async {
          guard let self = self else { return }
          if granted {
            self.messageInput = false
            self.startRecording()
          } else {
            self.alertTitle = "Microphone Access Denied"
            self.alertMessage = "To record audio, please enable microphone access in Settings."
            self.showPermissionAlert = true
          }
        }
      }
      
    case .restricted:
      alertTitle = "Microphone Access Restricted"
      alertMessage = "Microphone access is restricted and cannot be changed."
      showPermissionAlert = true
      
    @unknown default:
      break
    }
  }
      

  func openAppSettings() {
      guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
      if UIApplication.shared.canOpenURL(settingsURL) {
          UIApplication.shared.open(settingsURL)
      }
  }
}

extension ChatViewModel {
  func updateQueryParamsIfNeeded(_ oid: String) {
    if let ptOid = NwConfig.shared.queryParams["pt_oid"], ptOid.isEmpty {
      NwConfig.shared.queryParams["pt_oid"] = oid
    }
  }
}

extension Date {
  func toString(dateFormat format: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: self)
  }
}

class DocAssistFileHelper {
  
  public static func getDocumentDirectoryURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
}
