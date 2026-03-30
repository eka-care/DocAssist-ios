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

enum ChatErrorState {
  case none
  case sessionExpired
  case connectionError
}

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
  var initialMessageText: String? = nil
  var initialMessageSuggestions: [String]? = nil
  var chatErrorState: ChatErrorState = .none
  var webSocketErrorMessage: String? = nil
  
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
  
  /// Tracks pending file uploads: maps the request `_id` to the local image data
  private var pendingFileUploads: [String: Data] = [:]
  /// Tracks pending file MIME types: maps the request `_id` to its MIME type
  private var pendingFileUploadMimeTypes: [String: String] = [:]
  /// Tracks how many files are still pending upload before we send the text message
  private var pendingFileUploadCount: Int = 0
  /// Stores the text message to send after all file uploads complete
  private var pendingTextMessage: String?
  /// Collects the file IDs of successfully uploaded files
  private var uploadedFileIds: [String] = []

  func sendMessage(
    newMessage: String,
    imageUrls: [String]?,
    vaultFiles: [String]?,
    sessionId: String,
    lastMesssageId: Int?
  ) async {
    /// Create user message
    userMessage = await addUserMessage(
      newMessage,
      imageUrls,
      sessionId,
      lastMesssageId
    )

    let localImages = imageUrls ?? []
    if localImages.isEmpty {
      sendWebSocketMessage(message: newMessage)
    } else {
      // Send files first, then the text message after all uploads complete
      streamStarted = true
      pendingTextMessage = newMessage
      pendingFileUploadCount = localImages.count
      uploadedFileIds = []
      for (index, imagePath) in localImages.enumerated() {
        sendFileUploadRequest(imagePath: imagePath, offset: index)
      }
    }
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
      "ev": "chat",
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
      let activeSession = await checkIfSessionIsActive(for: webSocketSessionId)
      if activeSession {
        await webSocketAuthentication(sessionId: webSocketSessionId, sessionToken: UserDefaults.standard.string(forKey: "SessionToken")!)
      } else {
        print("#BB Session has expired")
        await MainActor.run {
          webSocketErrorMessage = "Session not found. Please start a new session."
          chatErrorState = .sessionExpired
        }
      }
    } else {
      //create session
    }
  }
  
  func checkIfSessionIsActive(for sessionId: String) async -> Bool {
    return await withCheckedContinuation { continuation in
      MatrixApiService.shared.checkSessionStatus(sessionId: sessionId) { [weak self] result, _ in
        switch result {
        case .success(let sessionResponse):
          print("#BB Data: Session is valid - \(sessionResponse.sessionID)")
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
  

  func refreshSession(for sessionId: String) async -> Bool {
    return await withCheckedContinuation { continuation in
      MatrixApiService.shared.refreshSession(sessionId: sessionId) { result, _ in
        switch result {
        case .success(let sessionResponse):
          print("#BB refreshSession success: \(sessionResponse.sessionID)")
          continuation.resume(returning: true)
        case .failure(let error):
          print("#BB refreshSession failure:", error.localizedDescription)
          continuation.resume(returning: false)
        }
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
    webSocketClient?.onConnectionError = { [weak self] error in
      guard let self else { return }
      Task { @MainActor in
        self.webSocketConnectionTitle = "Something went wrong"
        self.webSocketErrorMessage = "Something went wrong. Please try again."
        self.chatErrorState = .connectionError
        print("❌ WebSocket connection dropped: \(error.localizedDescription)")
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
  
  // MARK: - File Upload via WebSocket (3-step flow)

  /// Step 1: Send a file upload request to get presigned upload URLs
  func sendFileUploadRequest(imagePath: String, offset: Int = 0) {
    guard let webSocketClient else {
      print("❌ WebSocket not connected")
      return
    }

    let fileURL = DocAssistFileHelper.getDocumentDirectoryURL().appendingPathComponent(imagePath)
    guard let imageData = try? Data(contentsOf: fileURL) else {
      print("❌ Failed to read image data from: \(fileURL)")
      pendingFileUploadCount -= 1
      return
    }

    let ext = fileURL.pathExtension.lowercased()
    let mimeType: String
    switch ext {
    case "jpg", "jpeg": mimeType = "image/jpeg"
    case "pdf": mimeType = "application/pdf"
    default: mimeType = "image/png"
    }

    let timestamp = Int(Date().timeIntervalSince1970 * 1000) + offset
    let id = String(timestamp)

    // Store the image data keyed by request ID along with its MIME type
    pendingFileUploads[id] = imageData
    pendingFileUploadMimeTypes[id] = mimeType

    let payload: [String: Any] = [
      "ev": "chat",
      "ct": "file",
      "ts": timestamp,
      "_id": id,
      "data": [
        "extensions": [mimeType]
      ]
    ]

    do {
      let json = try JSONSerialization.data(withJSONObject: payload)
      if let jsonString = String(data: json, encoding: .utf8) {
        print("📤 Sending file upload request: \(jsonString)")
        webSocketClient.send(message: jsonString)
      }
    } catch {
      print("❌ File upload request encoding error: \(error)")
    }
  }

  /// Step 2: Handle the server response containing presigned upload URLs,
  /// upload the file to S3, then send the confirmation (Step 3).
  func handleFileUploadResponse(urls: [FileUploadURL], requestId: String?) {
    // Find the image data for this response
    // Try matching by requestId first, otherwise use the first pending upload
    let matchedId: String?
    if let requestId, pendingFileUploads[requestId] != nil {
      matchedId = requestId
    } else {
      matchedId = pendingFileUploads.keys.first
    }

    guard let id = matchedId, let imageData = pendingFileUploads.removeValue(forKey: id) else {
      print("❌ No pending file upload data found")
      return
    }
    let mimeType = pendingFileUploadMimeTypes.removeValue(forKey: id) ?? "image/png"

    guard let firstFile = urls.first else {
      print("❌ No upload URL received from server")
      return
    }

    let fileId = firstFile.id
    let uploadUrl = firstFile.url

    Task {
      WebSocketLogger.shared.logInfo("Uploading file: \(uploadUrl.prefix(80))...")
      let success = await uploadFileToPresignedURL(imageData: imageData, uploadURL: uploadUrl, mimeType: mimeType)
      if success {
        WebSocketLogger.shared.logInfo("Upload succeeded for file id: \(fileId)")
      } else {
        WebSocketLogger.shared.logInfo("Upload FAILED for: \(uploadUrl.prefix(80))...")
        print("❌ File upload failed")
      }

      await MainActor.run {
        if success {
          uploadedFileIds.append(fileId)
        }
        pendingFileUploadCount -= 1
        if pendingFileUploadCount <= 0 {
          // All files uploaded, send confirmation with file IDs and text
          if !uploadedFileIds.isEmpty {
            sendFileConfirmation(fileIds: uploadedFileIds, text: pendingTextMessage ?? "")
          }
          pendingTextMessage = nil
          pendingFileUploadCount = 0
          uploadedFileIds = []
        }
      }
    }
  }

  /// Upload image data to a presigned URL via HTTP PUT
  private func uploadFileToPresignedURL(imageData: Data, uploadURL: String, mimeType: String) async -> Bool {
    guard let url = URL(string: uploadURL) else {
      print("❌ Invalid upload URL: \(uploadURL)")
      return false
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.httpBody = imageData
    request.setValue(mimeType, forHTTPHeaderField: "Content-Type")

    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      if let httpResponse = response as? HTTPURLResponse,
         (200...299).contains(httpResponse.statusCode) {
        print("✅ File uploaded successfully to presigned URL")
        return true
      } else {
        print("❌ Upload failed with response: \(response)")
        return false
      }
    } catch {
      print("❌ Upload error: \(error)")
      return false
    }
  }

  /// Step 3: Send confirmation with uploaded file IDs and the user's text message
  func sendFileConfirmation(fileIds: [String], text: String) {
    guard let webSocketClient else {
      print("❌ WebSocket not connected")
      return
    }

    let timestamp = Int(Date().timeIntervalSince1970 * 1000)
    let id = String(timestamp)

    let payload: [String: Any] = [
      "ev": "chat",
      "ct": "file",
      "ts": timestamp,
      "_id": id,
      "data": [
        "urls": fileIds,
        "text": text
      ]
    ]

    do {
      let json = try JSONSerialization.data(withJSONObject: payload)
      if let jsonString = String(data: json, encoding: .utf8) {
        print("📤 Sending file confirmation: \(jsonString)")
        webSocketClient.send(message: jsonString)
      }
    } catch {
      print("❌ File confirmation encoding error: \(error)")
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
      if model.contentType == .tool,
         let toolName = model.data?.toolName,
         toolName == "elicit_selection",
         let details = model.data?.details {
        let optionValues = details.input.options.map { $0.value }
        let questionText = details.input.text
        let isMulti = details.component == "multi"
        DispatchQueue.main.async { [weak self] in
          self?.messageText = questionText
          self?.suggestions = optionValues
          self?.multiSelect = isMulti
        }
      } else if let text = model.data?.text {
        messageText += text
      } else if let progress = model.data?.text ?? model.data?.audio {
        DispatchQueue.main.async {
          print("⏳ Progress: \(progress)")
        }
      }
      
    case .err:
      let errorCode = model.data?.code.flatMap { WebSocketErrorCode(rawValue: $0) }
      
      switch errorCode {
        
      case .sessionInactive, .sessionTokenMismatch:
        await MainActor.run {
          webSocketConnectionTitle = "Session not found"
          webSocketErrorMessage = "Session not found. Please start a new session."
          chatErrorState = .sessionExpired
        }
        
      case .invalidEvent, .invalidContentType:
        print("⚠️ Ignorable WebSocket error (\(model.data?.code ?? ""))")
        
      case .parsingError:
        let sessionId = UserDefaults.standard.string(forKey: "SessionId") ?? vmssid
        let refreshed = await refreshSession(for: sessionId)
        if refreshed {
          let token = UserDefaults.standard.string(forKey: "SessionToken") ?? ""
          await webSocketAuthentication(sessionId: sessionId, sessionToken: token)
        } else {
          await MainActor.run {
            webSocketConnectionTitle = "Error parsing request"
            webSocketErrorMessage = "Error parsing request. Please try again."
            chatErrorState = .connectionError
          }
        }
        
      case .timeout:
        let sessionId = UserDefaults.standard.string(forKey: "SessionId") ?? vmssid
        let refreshed = await refreshSession(for: sessionId)
        if refreshed {
          let token = UserDefaults.standard.string(forKey: "SessionToken") ?? ""
          await webSocketAuthentication(sessionId: sessionId, sessionToken: token)
        } else {
          await MainActor.run {
            webSocketConnectionTitle = "Request timed out"
            webSocketErrorMessage = "Request timed out. Please try again."
            chatErrorState = .connectionError
          }
        }
        
      case .promptFetchError, .invalidFileRequest, .serverError, .none:
        let sessionId = UserDefaults.standard.string(forKey: "SessionId") ?? vmssid
        let refreshed = await refreshSession(for: sessionId)
        if refreshed {
          let token = UserDefaults.standard.string(forKey: "SessionToken") ?? ""
          await webSocketAuthentication(sessionId: sessionId, sessionToken: token)
        } else {
          await MainActor.run {
            webSocketConnectionTitle = "Something went wrong"
            webSocketErrorMessage = "Something went wrong. Please try again."
            chatErrorState = .connectionError
          }
        }
      }
      
    case .chat:
      if model.contentType == .file,
         let urls = model.data?.urls, !urls.isEmpty {
        handleFileUploadResponse(urls: urls, requestId: model.id)
      }
      else if (model.contentType == .audioTranscript || model.contentType == .inlineText),
         let transcribedText = model.data?.text {
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          self.inputString = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
          self.voiceProcessing = false
          self.messageInput = true
        }
      }
      
    case .eos:
      Task {
        await DatabaseConfig.shared.upsertMessageV2(responseMessage: messageText, userChat: userMessage, suggestions: suggestions, multiSelect: multiSelect)
        DispatchQueue.main.async { [weak self] in
          self?.messageText = ""
          self?.streamStarted = false
          self?.suggestions = nil
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
    
    // Reset initial message state for each new session creation attempt
    await MainActor.run {
      initialMessageText = nil
      initialMessageSuggestions = nil
    }
    
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
              
              if let initialMessage = sessionResponse.initialMessage {
                let text = initialMessage.text
               // let suggestions = initialMessage.suggestions
                await MainActor.run {
                  self.initialMessageText = text
               //   self.initialMessageSuggestions = suggestions
                }
              }
              
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

