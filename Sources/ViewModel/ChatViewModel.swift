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
import FirebaseFirestore

@Observable
public final class ChatViewModel: NSObject, URLSessionDataDelegate {
  
  /// Constant Strings
  private let role = "user"
  private let sessionId = "session_id"
  private let userAgent = "d-iOS"
  
  var streamStarted: Bool = false
  
  private(set) var vmssid: String = ""
  private var context: ModelContext
  private var delegate: ConvertVoiceToText? = nil
  private var deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil
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
  var initialMessage: InitialMessage? = nil
  var onFileUploadUrlsReceived: (([URLElement]) -> Void)?
  
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
    guard let webSocketSessionId = UserDefaults.standard.string(forKey: "SessionId"),
          let sessionToken = UserDefaults.standard.string(forKey: "SessionToken") else {
      return
    }

    let isActive = await checkIfSessionIsActive(for: webSocketSessionId)
    if isActive {
      await webSocketAuthentication(sessionId: webSocketSessionId, sessionToken: sessionToken)
    } else {
      await refreshSession(for: webSocketSessionId)
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
          "x-agent-id": "Y2I2MDk1MTgtYWZmNy00N2U0LWI5ZDctODRiMWM0ODMxNzcwIzcxNzU1Mzc2MzcxMjg5NDk="
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
          continuation.resume(returning: true)

        case .failure(_):
          continuation.resume(returning: false)
        }
      }
    }
  }

  /// Refreshes a session using GET /reloaded/med-assist/session/{id}/refresh.
  /// On success, updates the stored session token and re-authenticates the WebSocket.
  func refreshSession(for sessionId: String) async {
    let sessionToken = UserDefaults.standard.string(forKey: "SessionToken") ?? ""
    guard let url = URL(string: "https://matrix.eka.care/reloaded/med-assist/session/\(sessionId)/refresh") else {
      return
    }

    let networkRequest = HTTPNetworkRequest(
      url: url,
      method: .get,
      headers: [
        "Content-Type": "application/json",
        "x-agent-id": "Y2I2MDk1MTgtYWZmNy00N2U0LWI5ZDctODRiMWM0ODMxNzcwIzcxNzU1Mzc2MzcxMjg5NDk=",
        "x-sess-token": sessionToken
      ],
      body: nil
    )

    networkRequest.execute { [weak self] result in
      guard let self else { return }
      switch result {
      case .success(let data):
        print("#BB Refresh response:", String(data: data, encoding: .utf8) ?? "")
        if let response = try? JSONDecoder().decode(AuthSessionResponseModel.self, from: data) {
          UserDefaults.standard.set(response.sessionToken, forKey: "SessionToken")
          Task {
            await self.webSocketAuthentication(
              sessionId: response.sessionID,
              sessionToken: response.sessionToken
            )
          }
        }
      case .failure(let error):
        print("#BB refresh failure:", error.localizedDescription)
      }
    }
  }
  
  func webSocketAuthentication(sessionId: String, sessionToken: String) async {
    guard let url = URL(string: "wss://matrix-ws.eka.care/ws/med-assist/session/\(sessionId)/") else {
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
      if model.contentType == .tool {
        await handleToolEvent(model)
      } else if let text = model.data?.text {
        messageText += text
      }

    case .chat:
      if model.contentType == .file {
        // Server returned pre-signed upload URL(s)
        if let urls = model.data?.urls, !urls.isEmpty {
          DispatchQueue.main.async { [weak self] in
            self?.onFileUploadUrlsReceived?(urls)
          }
        }
      }

    case .eos:
      Task {
        await DatabaseConfig.shared.upsertMessageV2(
          responseMessage: messageText,
          userChat: userMessage,
          suggestions: suggestions,
          multiSelect: multiSelect
        )
        DispatchQueue.main.async { [weak self] in
          self?.messageText = ""
          self?.streamStarted = false
          self?.suggestions = nil
          self?.multiSelect = nil
        }
      }

    case .err:
      webSocketConnectionTitle = "\(model.msg ?? "error")"
      print("⚠️ WebSocket error event: \(model.msg ?? "Unknown error")")

    default:
      break
    }
  }

  // MARK: - File Upload Flow

  /// Step 1: Request a pre-signed upload slot from the server.
  /// The server responds with a `chat/file` event containing pre-signed URL(s).
  func requestFileUpload(extensions fileExtensions: [String]) {
    guard let webSocketClient else {
      print("❌ WebSocket not connected")
      return
    }

    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let payload: [String: Any] = [
      "ev": "chat",
      "ct": "file",
      "_id": String(timestamp),
      "ts": timestamp,
      "data": ["extensions": fileExtensions]
    ]

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: payload)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("📤 Requesting file upload slot: \(jsonString)")
        webSocketClient.send(message: jsonString)
      }
    } catch {
      print("❌ File upload request encoding error:", error)
    }
  }

  /// Step 3: Upload the file to the pre-signed URL using HTTP PUT.
  func uploadFileToPresignedUrl(data fileData: Data, urlString: String, mimeType: String, completion: @escaping (Result<Void, Error>) -> Void) {
    guard let url = URL(string: urlString) else {
      completion(.failure(URLError(.badURL)))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
    request.httpBody = fileData

    URLSession.shared.dataTask(with: request) { _, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }
      if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
        completion(.success(()))
      } else {
        completion(.failure(URLError(.badServerResponse)))
      }
    }.resume()
  }

  /// Step 4: Notify the server that the file has been uploaded successfully.
  func notifyFileUploaded(fileId: String) {
    guard let webSocketClient else {
      print("❌ WebSocket not connected")
      return
    }

    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let payload: [String: Any] = [
      "ev": "chat",
      "ct": "file",
      "_id": String(timestamp),
      "ts": timestamp,
      "data": ["urls": [fileId]]
    ]

    do {
      let jsonData = try JSONSerialization.data(withJSONObject: payload)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("📤 Notifying file uploaded: \(jsonString)")
        webSocketClient.send(message: jsonString)
      }
    } catch {
      print("❌ File uploaded notification encoding error:", error)
    }
  }

  private func handleToolEvent(_ model: WebSocketModel) async {
    guard let details = model.data?.details else { return }
    // Ignore if this tool call has already resolved
    if let status = details.status, status != .progress { return }

    let options = details.input.options.map { $0.value }
    let isMulti = details.component == .multi

    // Persist the tool question + options as a bot message immediately.
    // Tool events are self-contained — no eos follows them.
    await DatabaseConfig.shared.upsertMessageV2(
      responseMessage: details.input.text,
      userChat: userMessage,
      suggestions: options,
      multiSelect: isMulti
    )

    DispatchQueue.main.async { [weak self] in
      self?.messageText = ""
      self?.streamStarted = false
      self?.suggestions = nil
      self?.multiSelect = nil
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
        
        self.switchToSession(existingSessionId)
        Task {
          await self.webSocketAuthentication(
            sessionId: existingSessionId,
            sessionToken: existingToken ?? ""
          )
        }
        
        return existingSessionId
      }
    }
    
    print("🆕 Creating new session")

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
          "x-agent-id": "Y2I2MDk1MTgtYWZmNy00N2U0LWI5ZDctODRiMWM0ODMxNzcwIzcxNzU1Mzc2MzcxMjg5NDk="
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

                DispatchQueue.main.async {
                  self.initialMessage = sessionResponse.initialMessage
                }

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
  }
}

