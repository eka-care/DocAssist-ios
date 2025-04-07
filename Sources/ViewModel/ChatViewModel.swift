//
//  ChatViewModel.swift
//  Chatbot
//
//  Created by Brunda B on 12/11/24.
//

import SwiftUI
import SwiftData
import AVFAudio
import AVFoundation
import EkaVoiceToRx

public struct ExistingChatResponse {
  var chatExist: Bool
  var sessionId: [String]
}

@Observable
public final class ChatViewModel: NSObject, URLSessionDataDelegate {
  var streamStarted: Bool = false
  
  private(set) var vmssid: String = ""
  private var context: ModelContext
  private var delegate: ConvertVoiceToText? = nil
  private var deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil
  var liveActivityDelegate: LiveActivityDelegate? = nil
  
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
  var v2rxEnabled: Bool = true
  
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
  
  init(context: ModelContext, delegate: ConvertVoiceToText? = nil, deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil, liveActivityDelegate: LiveActivityDelegate? = nil) {
    self.context = context
    self.delegate = delegate
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
    self.liveActivityDelegate = liveActivityDelegate
  }
  
  func sendMessage(
    newMessage: String,
    imageUrls: [String]?,
    vaultFiles: [String]?,
    sessionId: String,
    lastMesssageId: Int?
  ) async {
    /// Create user message
    let userMessage =  await addUserMessage(
      newMessage,
      imageUrls,
      sessionId,
      lastMesssageId
    )
  
    /// Start streaming post request
    startStreamingPostRequest(
      vaultFiles: vaultFiles,
      userChat: userMessage
    )
  }
  
  private func addUserMessage(
    _ query: String,
    _ imageUrls: [String]?,
    _ sessionId: String,
    _ lastMessageId: Int?
  ) async -> ChatMessageModel? {
    var messageId: Int = 1
    if let lastMessageId = lastMessageId {
      messageId = lastMessageId + 1
    }
      let chat = await DatabaseConfig.shared.createMessage(
      message: query,
      sessionId: sessionId,
      messageId: messageId,
      role: .user,
      imageUrls: imageUrls
    )
    
    if chat?.msgId == 1 {
      await DatabaseConfig.shared.saveTitle(sessionId: sessionId, title: query)
    }
    
    return chat
  }
  
  static let dispatchSemaphore = DispatchSemaphore(value: 1)
  
  func startStreamingPostRequest(vaultFiles: [String]?, userChat: ChatMessageModel?) {
    guard let userChat else { return }
    DispatchQueue.main.async { [weak self] in
      self?.streamStarted = true
    }
    NetworkConfig.shared.queryParams["session_id"] = userChat.sessionId
    networkCall.startStreamingPostRequest(query: userChat.messageText, vault_files: vaultFiles, onStreamComplete: { [weak self] in
      
      DispatchQueue.main.async { [weak self] in
        self?.streamStarted = false
      }
    }) { [weak self] result in
      guard let self else {
        return
      }
      Task {
        switch result {
        case .success(let responseString):
          await self.handleStreamResponse(responseString: responseString, userChat: userChat)
        case .failure(let error):
          print("Error streaming: \(error)")
        }
      }
    }
  }
  
  func handleStreamResponse(responseString: String, userChat: ChatMessageModel) async {
      let splitLines = responseString.split(separator: "\n")

      var message: Message?

      for line in splitLines {
          guard line.contains("data:") else { continue }
          guard let jsonRange = line.range(of: "{") else { return }

          let jsonString = String(line[jsonRange.lowerBound...])
          guard let jsonData = jsonString.data(using: .utf8) else { return }

          do {
              message = try JSONDecoder().decode(Message.self, from: jsonData)
          } catch {
              print("Failed to decode JSON: \(error.localizedDescription)")
          }
      }
    
    await MainActor.run {
      Task {
        await DatabaseConfig.shared.upsertMessageV2(responseMessage: message?.text ?? "", userChat: userChat)
      }
    }
  }
  
  func isSessionsPresent(oid: String, userDocId: String, userBId: String) async -> Bool {
    do {
      let sessions = try await DatabaseConfig.shared.fetchSessionId(fromOid: oid, userDocId: userDocId, userBId: userBId)
      
      if sessions.count > 0 {
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
    let createSessionModel = SessionDataModel(sessionId: ssid, createdAt: currentDate, lastUpdatedAt: currentDate, title: "New Chat", subTitle: subTitle, oid: oid, userDocId: userDocId, userBId: userBId)
    await DatabaseConfig.shared.insertSession(session: createSessionModel)
    await DatabaseConfig.shared.saveData()
    switchToSession(ssid)
    return ssid
  }
  
  func switchToSession(_ id: String) {
    vmssid = id
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
  
  func stopStreaming() {
      networkCall.cancelStreaming()
      streamStarted = false
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
    if let ptOid = NetworkConfig.shared.queryParams["pt_oid"], ptOid.isEmpty {
      NetworkConfig.shared.queryParams["pt_oid"] = oid
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

extension Notification.Name {
  static let addedMessage = Notification.Name("addedMessage")
}

extension ChatViewModel {
  func navigateToDeepThought(id: String?) {
    guard let id else { return }
    deepThoughtNavigationDelegate?.navigateToDeepThoughtPage(id: id)
  }
}

extension ChatViewModel {
  
  public func fetchVoiceConversations(using sessionId: UUID) async -> String? {
    let fetchDescriptor = FetchDescriptor<VoiceConversationModel>(
      predicate: #Predicate { $0.id == sessionId }
    )
    let result = await VoiceConversationAggregator.shared.fetchVoiceConversation(using: fetchDescriptor)
    return result.first?.fileURL
  }
  
  public func checkForVoiceToRxResult(using sessionId: UUID?) async -> Bool {
    guard let sessionId else { return true }
    
    let fetchDescriptor = FetchDescriptor<VoiceConversationModel>(
      predicate: #Predicate { $0.id == sessionId }
    )
    
    let result = await VoiceConversationAggregator.shared.fetchVoiceConversation(using: fetchDescriptor)
    
    if let result = result.first { /// If we found v2rx session with completed session we enable mic
      return result.didFetchResult != nil
    } else { /// If no v2rx session is found means it was deleted and we enable mic again
      return true
    }
  }
}

extension ChatViewModel {
  public func createV2rxChat(oId: String, userDocId:String, userBId: String, sessionId: String) async {
    let session = await createSession(subTitle: nil, oid: oId, userDocId: userDocId, userBId: userBId)
    let _ = await DatabaseConfig.shared.createMessage(sessionId: sessionId, messageId: 0 , role: .Bot, imageUrls: nil)
  }
}
