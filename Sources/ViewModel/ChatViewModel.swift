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
import FirebaseFirestore

public struct ExistingChatResponse {
  var chatExist: Bool
  var sessionId: [String]
}

@Observable
public final class ChatViewModel: NSObject, URLSessionDataDelegate {
  
  /// Constant Strings
  private let role = "user"
  private let sessionId = "session_id"
  private let userAgent = "d-iOS"
  private var firestoreListener: ListenerRegistration?
  
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
  var userBid: String
  var userDocId: String
  var patientName: String
  var isOidPresent: String? = ""
  
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
  
  init(
    context: ModelContext,
    delegate: ConvertVoiceToText? = nil,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil,
    liveActivityDelegate: LiveActivityDelegate? = nil,
    userBid: String,
    userDocId: String,
    patientName: String = ""
  ) {
    self.context = context
    self.delegate = delegate
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
    self.liveActivityDelegate = liveActivityDelegate
    self.userBid = userBid
    self.userDocId = userDocId
    self.patientName = patientName
  }
  
  func sendMessage(newMessage: String) {
     addUserMessage(newMessage)
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
          sessionId: fetchedSeesion
        )
        fetchedSeesion.chatMessages.append(userData)
      }
    } catch {
      print("Unable to fetch data")
    }
    
    
      // send  message to firestore
      
      // start listening to it for data assistant
      
      // save data
      
      // and delete the old session
      
    
    saveData()
    setThreadTitle(with: query)
    startStreamingPostRequest(query: query)
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
  
   func updateMessage(with message: Message) {
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
      
    ///Firestore handling
    let ownerId = userDocId + "_" + userBid
    DispatchQueue.main.async { [weak self] in
        self?.streamStarted = true
    }
//      Task {
//          do {
//              isOidPresent = try await DatabaseConfig.shared.isOidPreset(sessionId: userChat.sessionId)
//              
//              // Calculate patientContext after getting isOidPresent
//              let patientContext = isOidPresent != nil && isOidPresent != ""
//              
//            /// if patient context is true then chat context should be a json object which as field oid and patientName
//            
//            var chatContext: String? = nil
//            if let oid = isOidPresent, !oid.isEmpty {
//                let contextDict: [String: String] = [
//                    "patientId": oid,
//                    "patientName": patientName
//                ]
//                if let jsonData = try? JSONSerialization.data(withJSONObject: contextDict, options: []),
//                   let jsonString = String(data: jsonData, encoding: .utf8) {
//                    chatContext = jsonString
//                }
//            }
//
//              DocAssistFireStoreManager.shared
//                  .sendMessageToFirestore(
//                      businessId: userBid,
//                      doctorId: userDocId,
//                      context: patientContext,
//                      sessionId: userChat.sessionId,
//                      messageId: userChat.msgId - 1,
//                      message: .init(
//                          message: userChat.messageText ?? "",
//                          sessionId: userChat.sessionId,
//                          doctorId: userDocId,
//                          patientId: isOidPresent ?? "", // Use the fetched OID
//                          role: role,
//                          vaultFiles: userChat.imageUrls,
//                          userAgent: userAgent,
//                          ownerId: ownerId,
//                          createdAt: Int64(Date().timeIntervalSince1970 * 1000),
//                          chatContext: chatContext
//                      )
//                  ) { [weak self] str in
//                      guard let self else { return }
//                      print("Message sent to Firestore: \(str)")
//                      self.startFirestoreListener(userChat: userChat)
//                  }
//          } catch {
//              print("#BB Error determining OID presence: \(error)")
//          }
//      }

      
    /// Stream api
      NetworkConfig.shared.queryParams[sessionId] = userChat.sessionId
      networkCall.startStreamingPostRequest(query: userChat.messageText, vault_files: vaultFiles, onStreamComplete: { [weak self] in
          DispatchQueue.main.async { [weak self] in
              self?.streamStarted = false
          }
      }) { [weak self] result in
          guard let self else { return }
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
  
  func startFirestoreListener(userChat: ChatMessageModel) {
    let patientContext = isOidPresent != nil && !isOidPresent!.isEmpty
      
    DocAssistFireStoreManager.shared.listenToFirestoreMessages(
      businessId: self.userBid,
      doctorId: self.userDocId,
      sessionId: userChat.sessionId,
      context: patientContext,  // Added context parameter
      patientId: self.isOidPresent ?? "",
      messageId: userChat.msgId
    ) { [weak self] data in
      guard let self = self else { return }
      
      if let message = data["message"] as? String,
         let status = data["status"] as? String,
         let role = data["role"] as? String,
         role == "assistant" {
        Task { @MainActor in
            await DatabaseConfig.shared.upsertMessageV2(
              responseMessage: message,
              userChat: userChat
            )
        }
      }
      
      if let eof = data["is_eof"] as? Bool, eof == true {
        DispatchQueue.main.async { [weak self] in
          self?.streamStarted = false
        }
      }
      
    }
  }
  
  /// Stream response handling
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
  
  public func createSession(subTitle: String?, oid: String = "", userDocId: String, userBId: String) async -> String {
    //    let currentDate = Date()
    //    let ssid = UUID().uuidString
    //    let createSessionModel = SessionDataModel(sessionId: ssid, createdAt: currentDate, lastUpdatedAt: currentDate, title: "New Chat", subTitle: subTitle, oid: oid, userDocId: userDocId, userBId: userBId)
    //    await DatabaseConfig.shared.insertSession(session: createSessionModel)
    //    await DatabaseConfig.shared.saveData()
    let session = await DatabaseConfig.shared.createSession(subTitle: subTitle,oid: oid, userDocId: userDocId, userBId: userBId)
    switchToSession(session)
    return session
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

extension Data {
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
}

extension ChatViewModel {
  func stopFirestoreStream() {
    firestoreListener?.remove()
    firestoreListener = nil
    streamStarted = false
  }
}
