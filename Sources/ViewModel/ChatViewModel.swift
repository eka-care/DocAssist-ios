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
  var suggestionsDelegate: GetMoreSuggestions? = nil
  var getPatientDetailsDelegate: GetPatientDetails? = nil
  
  private let networkCall = NetworkCall()
  private var webSocketClient: WebSocketNetworkRequest?
  
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
  var lastMsgId: Int?
  var showTranscriptionFailureAlert = false
  var openType: String?
  var userMessage: ChatMessageModel?
  var messageText: String = ""
  let serialTaskQueue = SerialTaskQueue()
  var suggestions: [String]? = nil
  var multiSelect: Bool? = nil
  var webSocketConnectionTitle: String = "Idle"
  
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
  
  var delay = 0.0
  var showTranscriptionFailureAlertBinding: Binding<Bool> {
    Binding { [weak self] in
      self?.showTranscriptionFailureAlert ?? false
    } set: { [weak self] newValue in
      self?.showTranscriptionFailureAlert = newValue
    }
  }
  
  init(
    context: ModelContext,
    delegate: ConvertVoiceToText? = nil,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil,
    liveActivityDelegate: LiveActivityDelegate? = nil,
    userBid: String,
    userDocId: String,
    patientName: String = "",
    suggestionsDelegate: GetMoreSuggestions? = nil,
    getPatientDetailsDelegate: GetPatientDetails? = nil,
    openType: String? = nil
  ) {
    self.context = context
    self.delegate = delegate
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
    self.liveActivityDelegate = liveActivityDelegate
    self.userBid = userBid
    self.userDocId = userDocId
    self.patientName = patientName
    self.suggestionsDelegate = suggestionsDelegate
    self.getPatientDetailsDelegate = getPatientDetailsDelegate
    self.openType = openType
  }
  
  func sendMessage(
    newMessage: String,
    imageUrls: [String]?,
    vaultFiles: [String]?,
    sessionId: String,
    lastMesssageId: Int?
  ) async {
    /// Create user message
    userMessage =  await addUserMessage(
      newMessage,
      imageUrls,
      sessionId,
      lastMesssageId
    )
    
    sendWebSocketMessage(message: newMessage)
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
    print("#BB msgId in send \(messageId)")
    self.lastMsgId = messageId + 1
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
  
  //  public func createSession(subTitle: String?, oid: String = "", userDocId: String, userBId: String) async -> String {
  //    let session = await DatabaseConfig.shared.createSession(subTitle: subTitle,oid: oid, userDocId: userDocId, userBId: userBId)
  //    switchToSession(session)
  //    return session
  //  }
  
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
      let fileName = Date().toString(dateFormat: "dd-MM-YY_'at'_HH:mm:ss") + ".m4a"
      let audioURL = documentsPath.appendingPathComponent(fileName)
      
      let settings = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      
      audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
      audioRecorder?.delegate = self
      audioRecorder?.record()
      
      isRecording = true
      currentRecording = audioURL
    } catch {
      print("Could not start recording: \(error)")
    }
  }
  
  func stopRecording() {
    guard isRecording, let recorder = audioRecorder, let url = currentRecording else {
      print("No recording to stop.")
      return
    }
    
    recorder.stop()
    DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
      do {
        self?.voiceProcessing = true
        let audioData = try Data(contentsOf: url)
        let base64String = audioData.base64EncodedString()
        self?.sendAudioBase64ToServer(base64String)
        self?.isRecording = false
        self?.audioRecorder = nil
      } catch {
        print("❌ Failed to read audio file:", error)
      }
    }
  }
  
  func sendAudioBase64ToServer(_ base64String: String) {
    guard let webSocketClient else {
      print("❌ WebSocket not connected")
      return
    }
    
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let id = String(timestamp)
    
    let payload: [String: Any] = [
      "ev": "stream",
      "ct": "audio",
      "ts": timestamp,
      "_id": id,
      "data": [
        "audio": base64String,
        "format": "audio/mp4"
      ]
    ]
    
    do {
      let json = try JSONSerialization.data(withJSONObject: payload)
      if let jsonString = String(data: json, encoding: .utf8) {
        print("📤 Sending audio message: \(jsonString)")
        webSocketClient.send(message: jsonString)
      }
    } catch {
      print("❌ Audio payload encoding error:", error)
    }
  }
  
  func dontRecord() {
    guard isRecording, let recorder = audioRecorder else {
      print("No recording to stop.")
      return
    }
    recorder.stop()
    messageInput = true
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
    NetworkConfig.shared.queryParams["pt_oid"] = oid
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

extension Data {
  func toString() -> String? {
    return String(data: self, encoding: .utf8)
  }
}


// MARK: - Web Socket flow
extension ChatViewModel {
  
  func checkandValidateWebSocketConnection() async {
    
    let webSocketSessionId = UserDefaults.standard.string(forKey: "SessionId")
    if let webSocketSessionId {
      await checkIfSessionIsActive(for: webSocketSessionId)
      Task {
        await self.webSocketAuthentication(sessionId: webSocketSessionId, sessionToken: UserDefaults.standard.string(forKey: "SessionToken")!)
      }
    } else {
      // await createSession()
    }
  }
  
  func checkIfSessionIsActive(for sessionId: String) async -> Bool {
    guard let url = URL(string: "https://matrix.eka.care/reloaded/med-assist/session/\(sessionId)") else {
      return false
    }
    
    return await withCheckedContinuation { continuation in
      let networkRequest = HTTPNetworkRequest(
        url: url,
        method: .get,
        headers: [
          "Content-Type": "application/json",
          "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
        ],
        body: nil
      )
      
      networkRequest.execute { [weak self] result in
        switch result {
        case .success(let data):
          print("#BB Data:", String(data: data, encoding: .utf8)!)
          DispatchQueue.main.async {
            self?.webSocketConnectionTitle = "Connected"
          }
          continuation.resume(returning: true)   // Session is valid
          
        case .failure(_):
          continuation.resume(returning: false)  // Not active or expired
        }
      }
    }
  }
  
  func refreshSession(for sessionId: String) async {
    guard let url = URL(string: "https://matrix.eka.care/med-assist/reloaded/session/\(sessionId)/refresh") else  {
      return
    }
    
    let networkRequest = HTTPNetworkRequest(
      url: url,
      method: .post,
      headers: ["Content-Type": "application/json", "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId],
      body: nil
    )
    
    networkRequest.execute { result in
      switch result {
      case .success(let data):
        print(""
              , String(data: data, encoding: .utf8)!)
      case .failure(let error):
        print("#BB failure error:", error.localizedDescription)
      }
    }
  }
  
  func webSocketAuthentication(sessionId: String, sessionToken: String) async {
    guard let url = URL(string: "wss://matrix-ws.eka.care/reloaded/ws/med-assist/session/\(sessionId)/") else {
      print("❌ Invalid WebSocket URL")
      webSocketConnectionTitle = "Not connected"
      return
    }
    
    webSocketClient = WebSocketNetworkRequest(url: url)
    webSocketClient?.onMessageDecoded = { [weak self] model in
      guard let self else { return }
      serialTaskQueue.enqueue { [weak self] in
        guard let self else { return }
        await handleWebSocketModel(model)
      }
    }
    webSocketClient?.connect { [weak self] connected in
      guard connected else {
        print("❌ WebSocket connection failed")
        self?.webSocketConnectionTitle = "Not connected"
        return
      }
      
      self?.webSocketConnectionTitle = "Connected"
      
      // Generate unique ID & timestamp
      let timestamp = Int(Date().timeIntervalSince1970 * 1000)
      let authId = String(timestamp)
      
      // Construct auth payload
      let authPayload: [String: Any] = [
        "ev": "auth",
        "_id": authId,
        "ts": timestamp,
        "data": [
          "token": sessionToken
        ]
      ]
      
      // Convert to JSON string
      do {
        let jsonData = try JSONSerialization.data(withJSONObject: authPayload, options: [])
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          print("📤 Sending auth message: \(jsonString)")
          self?.webSocketClient?.send(message: jsonString)
        }
      } catch {
        print("❌ Failed to encode auth payload: \(error)")
      }
    }
  }
  
  func sendWebSocketMessage(message: String) {
    guard let webSocketClient else {
      print("❌ WebSocket not connected")
      return
    }
    
    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    
    let data = WebSocketData(text: message)
    
    let webSocketMessage = WebSocketModel(
      eventType: .chat,
      ts: timestamp,
      id: String(timestamp),
      contentType: .text,
      msg: nil,
      data: data
    )
    streamStarted = true
    do {
      let jsonData = try JSONEncoder().encode(webSocketMessage)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("📤 Sending message: \(jsonString)")
        webSocketClient.send(message: jsonString)
      }
    } catch {
      print("❌ Failed to encode WebSocket message: \(error)")
    }
  }
  
  func handleWebSocketModel(_ model: WebSocketModel) async {
    switch model.eventType {
    case .stream:
      if let text = model.data?.text {
        messageText += text
      } else if let progress = model.data?.text ?? model.data?.audio {
        DispatchQueue.main.async {
          print("⏳ Progress: \(progress)")
        }
      }
      
    case .err:
      webSocketConnectionTitle = "\(model.msg)"
      print("⚠️ WebSocket error event: \(model.msg ?? "Unknown error")")
      
    case .chat:
      if let choice = model.contentType {
        if choice == .pill {
          if let choices = model.data?.choices {
            suggestions = choices
            multiSelect = false
          }
        } else if choice == .multi {
          if let choices = model.data?.choices {
            suggestions = choices
            multiSelect = true
          }
        } else if choice == .inline_text {
          if let textData = model.data?.text {
            voiceProcessing = false
            messageInput = true
            inputString = textData
          }
        }
      }
      
    case .eos:
      Task {
        await DatabaseConfig.shared.upsertMessageV2(responseMessage: messageText, userChat: userMessage, suggestions: suggestions, multiSelect: multiSelect)
        DispatchQueue.main.async { [weak self] in
          self?.messageText = ""
          self?.streamStarted = false
          self?.multiSelect = nil
        }
      }
      
    default:
      break
    }
  }
  
  public func createSession(
    subTitle: String?,
    oid: String = "",
    userDocId: String,
    userBId: String
  ) async -> String {
    
    if let existing = try? await DatabaseConfig.shared
      .fetchSessionIdwithoutoid(userDocId: userDocId, userBId: userBId)
      .last {
      
      let existingSessionId = existing.sessionId
      let existingToken = existing.sessionToken
      
      if await checkIfSessionIsActive(for: existingSessionId) {
        print("🔄 Reusing existing session: \(existingSessionId)")
        
        switchToSession(existingSessionId)
        Task {
          await webSocketAuthentication(
            sessionId: existingSessionId,
            sessionToken: existingToken ?? ""
          )
        }
        
        return existingSessionId
      }
    }
    
    print("🆕 Creating new session")
    
    // MARK: - Old implementation (commented out)
    /*
    guard let url = URL(string: "https://matrix.eka.care/reloaded/med-assist/session") else {
      return ""
    }
    
    do {
      let requestBody = try JSONEncoder().encode(AuthSessionRequestModel(uerId: userDocId))
      
      let networkRequest = HTTPNetworkRequest(
        url: url,
        method: .post,
        headers: [
          "Content-Type": "application/json",
          "x-agent-id": AuthAndUserDetailsSetter.shared.xAgentId
        ],
        body: requestBody
      )
      
      return try await withCheckedThrowingContinuation { continuation in
        networkRequest.execute { [weak self] result in
          guard let self else { return }
          
          switch result {
          case .success(let data):
            do {
              let sessionResponse = try JSONDecoder().decode(AuthSessionResponseModel.self, from: data)
              
              Task {
                let _ = await DatabaseConfig.shared.createSession(
                  subTitle: subTitle,
                  oid: oid,
                  userDocId: userDocId,
                  userBId: userBId,
                  sessionId: sessionResponse.sessionID,
                  sessionToken: sessionResponse.sessionToken
                )
                
                self.switchToSession(sessionResponse.sessionID)
                
                await self.webSocketAuthentication(
                  sessionId: sessionResponse.sessionID,
                  sessionToken: sessionResponse.sessionToken
                )
                
                continuation.resume(returning: sessionResponse.sessionID)
              }
              
            } catch {
              continuation.resume(throwing: error)
            }
            
          case .failure(let error):
            continuation.resume(throwing: error)
          }
        }
      }
    } catch {
      print("Encoding error: \(error)")
      return ""
    }
    */
    
    // MARK: - New Alamofire implementation using Matrix Provider
    let requestModel = AuthSessionRequestModel(uerId: userDocId)
    
    do {
     return try await withCheckedThrowingContinuation { continuation in
        
        MatrixApiService.shared.createSession(requestModel: requestModel) { [weak self] result, _ in
          guard let self else { return }
          
          switch result {
          case .success(let sessionResponse):
            Task {
              let _ = await DatabaseConfig.shared.createSession(
                subTitle: subTitle,
                oid: oid,
                userDocId: userDocId,
                userBId: userBId,
                sessionId: sessionResponse.sessionID,
                sessionToken: sessionResponse.sessionToken
              )
              
              self.switchToSession(sessionResponse.sessionID)
              
              await self.webSocketAuthentication(
                sessionId: sessionResponse.sessionID,
                sessionToken: sessionResponse.sessionToken
              )
              
              continuation.resume(returning: sessionResponse.sessionID)
            }
            
          case .failure(let error):
            continuation.resume(throwing: error)
          }
        }
      }
    } catch {
      print("Error creating session: \(error)")
      return ""
    }
  }
}

