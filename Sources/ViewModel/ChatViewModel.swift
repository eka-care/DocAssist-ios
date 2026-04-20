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

@Observable @MainActor
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
  var lastSessionRecoveryReason: String? = nil
  var isWebSocketSetupDone: Bool = false
  
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

  @MainActor
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
    // Single actor hop: creates the message and sets the session title (if first message)
    // in one modelContext.save() call, avoiding a second cross-actor round-trip.
    let chat = await DatabaseConfig.shared.createUserMessageWithTitle(
      message: query,
      sessionId: sessionId,
      messageId: messageId,
      imageUrls: imageUrls
    )
    return chat
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
      
      let documentsPath = DocAssistFileHelper.getDocumentDirectoryURL()
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
    // Read the audio file off the main thread but mutate @Observable properties
    // only on the MainActor to avoid SwiftUI threading violations.
    // Task(priority:) inherits actor context and cancellation from the caller;
    // we do NOT use Task.detached here so that cancellation propagates correctly.
    Task(priority: .userInitiated) {
      try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s wait for file flush
      do {
        // File I/O is blocking — suspend off the main thread with a throwing continuation.
        let audioData: Data = try await withCheckedThrowingContinuation { continuation in
          DispatchQueue.global(qos: .userInitiated).async {
            do {
              let data = try Data(contentsOf: url)
              continuation.resume(returning: data)
            } catch {
              continuation.resume(throwing: error)
            }
          }
        }
        let base64String = audioData.base64EncodedString()
        await MainActor.run {
          self.voiceProcessing = true
          self.isRecording = false
          self.audioRecorder = nil
        }
        sendAudioBase64ToServer(base64String)
      } catch {
        print("❌ Failed to read audio file:", error)
        await MainActor.run {
          self.isRecording = false
          self.audioRecorder = nil
        }
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
    // Always fetch session from DB scoped to this user — never from UserDefaults.
    guard let dbSession = try? await DatabaseConfig.shared
      .fetchSessionIdwithoutoid(userDocId: userDocId, userBId: userBid)
      .last else {
      WebSocketLogger.shared.logInfo("checkandValidateWebSocketConnection — no session in DB for user, skipping reconnection")
      return
    }

    let webSocketSessionId = dbSession.sessionId
    let token = dbSession.sessionToken ?? ""
    WebSocketLogger.shared.logInfo("checkandValidateWebSocketConnection called — sessionId: \(webSocketSessionId)")

    let statusResult = await checkSessionStatus(for: webSocketSessionId)
    WebSocketLogger.shared.logInfo("Session check result: \(statusResult)")

    switch statusResult {
    case .active:
      // Re-fetch token from DB after the session check — checkSessionStatus may have rotated it.
      let latestToken = (try? await DatabaseConfig.shared.fetchSession(bySessionId: webSocketSessionId))?.sessionToken ?? token
      let connectToken = latestToken.isEmpty ? token : latestToken
      if !connectToken.isEmpty {
        // Clear any stale error banner before reconnecting.
        await MainActor.run {
          chatErrorState = .none
          webSocketErrorMessage = nil
          lastSessionRecoveryReason = nil
        }
        await webSocketAuthentication(sessionId: webSocketSessionId, sessionToken: connectToken)
      } else {
        WebSocketLogger.shared.logInfo("Session active but SessionToken missing — skipping WebSocket auth")
      }
    case .networkError:
      // Transient failure (auth token decode error, no network, interceptor retry failed).
      // Attempt to reconnect with the token we have rather than showing an error banner.
      WebSocketLogger.shared.logInfo("Session check had transient error — attempting reconnect with stored token")
      if !token.isEmpty {
        await webSocketAuthentication(sessionId: webSocketSessionId, sessionToken: token)
      }
    case .expired:
      print("#BB Session has expired — showing refresh banner")
      WebSocketLogger.shared.logInfo("Session \(webSocketSessionId) is no longer active — prompting user to refresh")
      await MainActor.run {
        // Ensure vmssid is set so the Retry button can use the correct session ID.
        if vmssid.isEmpty {
          vmssid = webSocketSessionId
        }
        lastSessionRecoveryReason = "session_check_expired"
        webSocketErrorMessage = "Session expired. Tap to refresh."
        chatErrorState = .connectionError
      }
    }
  }
  
  enum SessionCheckResult: Equatable {
    case active       // Server confirmed session is valid
    case expired      // Server returned a 4xx — session is genuinely gone
    case networkError // Call failed for a reason unrelated to session validity (auth token issue, decode error, no network)
  }

  func checkIfSessionIsActive(for sessionId: String) async -> Bool {
    let result = await checkSessionStatus(for: sessionId)
    switch result {
    case .active: return true
    case .expired: return false
    case .networkError:
      // Can't confirm either way — assume still valid to avoid unnecessary new session creation
      print("#BB checkIfSessionIsActive — network/decode error, assuming session still valid: \(sessionId)")
      return true
    }
  }

  private func checkSessionStatus(for sessionId: String) async -> SessionCheckResult {
    // Bridge the callback into async. Capture only the server token (a value type),
    // never a SwiftData model object, across the actor boundary.
    let (result, serverToken): (SessionCheckResult, String?) = await withCheckedContinuation { continuation in
      MatrixApiService.shared.checkSessionStatus(sessionId: sessionId) { [weak self] result, statusCode in
        switch result {
        case .success(let sessionResponse):
          print("#BB Session is valid - \(sessionResponse.sessionID)")
          let token = sessionResponse.sessionData.sessionToken
          DispatchQueue.main.async {
            self?.webSocketConnectionTitle = "Connected"
          }
          continuation.resume(returning: (.active, token))

        case .failure(let error):
          let code = statusCode ?? 0
          let errorMessage = error.localizedDescription
          print("#BB checkSessionStatus failed — statusCode: \(code), error: \(errorMessage)")
          // Only treat explicit 4xx as a real expiry; everything else (network, decode, interceptor) is a transient error
          if code >= 400 && code < 500 {
            print("#BB Session \(sessionId) is expired (4xx from server)")
            continuation.resume(returning: (.expired, nil))
          } else {
            print("#BB Session check failed due to transient error — not treating as expired")
            continuation.resume(returning: (.networkError, nil))
          }
        }
      }
    }

    // Persist rotated token on the DB actor — safely outside the continuation.
    if result == .active, let serverToken, !serverToken.isEmpty {
      await DatabaseConfig.shared.updateSessionToken(sessionId: sessionId, sessionToken: serverToken)
    }
    return result
  }
  

  /// Returns the new session token from the server after a successful refresh, or `nil` on failure.
  func refreshSession(for sessionId: String) async -> String? {
    // Fetch current token from DB — never from UserDefaults to avoid cross-profile contamination.
    let currentToken = (try? await DatabaseConfig.shared.fetchSession(bySessionId: sessionId))?.sessionToken ?? ""

    // Use AsyncStream bridge so the DB write completes before we return the token,
    // without capturing the continuation inside a nested Task (which would violate
    // the single-resume contract if the outer scope deallocates concurrently).
    let newToken: String? = await withCheckedContinuation { continuation in
      MatrixApiService.shared.refreshSession(sessionId: sessionId, sessionToken: currentToken) { result, _ in
        switch result {
        case .success(let sessionResponse):
          // Refresh endpoint returns a flat response: session_token is a top-level field,
          // not nested inside session_data (which is only present on checkSessionStatus).
          let token = sessionResponse.sessionToken
          print("#BB refreshSession success: \(sessionResponse.sessionID)")
          guard !token.isEmpty else {
            Task { @MainActor in WebSocketLogger.shared.logInfo("refreshSession: empty session_token in response") }
            continuation.resume(returning: nil)
            return
          }
          continuation.resume(returning: token)
        case .failure(let error):
          print("#BB refreshSession failure:", error.localizedDescription)
          continuation.resume(returning: nil)
        }
      }
    }

    if let newToken {
      // Persist the new token on the DB actor — now safely outside the continuation.
      await DatabaseConfig.shared.updateSessionToken(sessionId: sessionId, sessionToken: newToken)
    } else {
      await MainActor.run {
        self.lastSessionRecoveryReason = "refresh_failed"
      }
    }
    return newToken
  }
  
  func webSocketAuthentication(sessionId: String, sessionToken: String) async {
    guard let url = URL(string: "wss://matrix-ws.eka.care/reloaded/ws/med-assist/session/\(sessionId)/") else {
      print("❌ Invalid WebSocket URL")
      webSocketConnectionTitle = "Not connected"
      return
    }
    await MainActor.run {
      webSocketConnectionTitle = "Connecting..."
    }
    
    // Always tear down any existing socket before opening a new one
    // so token refresh re-auth starts from a clean transport.
    webSocketClient?.disconnect()
    
    let socketClient = WebSocketNetworkRequest(url: url)
    webSocketClient = socketClient
    socketClient.onMessageDecoded = { [weak self] model in
      guard let self else { return }
      serialTaskQueue.enqueue { [weak self] in
        guard let self else { return }
        await handleWebSocketModel(model)
      }
    }
    socketClient.onConnectionError = { [weak self] error in
      guard let self else { return }
      Task { @MainActor in
        self.lastSessionRecoveryReason = "websocket_transport_error"
        self.webSocketConnectionTitle = "Something went wrong"
        self.webSocketErrorMessage = "Something went wrong. Please try again."
        self.chatErrorState = .connectionError
        WebSocketLogger.shared.logInfo("Error state: connectionError — WebSocket connection dropped: \(error.localizedDescription)")
        print("❌ WebSocket connection dropped: \(error.localizedDescription)")
      }
    }
    socketClient.connect { [weak self] connected in
      guard connected else {
        print("❌ WebSocket connection failed")
        WebSocketLogger.shared.logInfo("Error: WebSocket initial connection failed to \(url)")
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
      
      // Convert to JSON string — use self.webSocketClient (the property) rather than
      // a weak-captured local variable, which may be nil by the time this callback fires.
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
        await MainActor.run {
          messageText = questionText
          suggestions = optionValues
          multiSelect = isMulti
        }
      } else if let text = model.data?.text {
        await MainActor.run {
          messageText += text
        }
      } else if let progress = model.data?.text ?? model.data?.audio {
        print("⏳ Progress: \(progress)")
      }
      
    case .err:
      let errorCode = model.data?.code.flatMap { WebSocketErrorCode(rawValue: $0) }
      let rawCode = model.data?.code ?? "unknown"
      let rawMsg = model.data?.msg ?? model.data?.text ?? "no message"
      WebSocketLogger.shared.logInfo("WS error received — code: \(rawCode), msg: \(rawMsg)")
      
      switch errorCode {
        
      case .sessionInactive, .sessionTokenMismatch:
        // Session is truly invalid — retry with same token won't work, user must start a new session
        WebSocketLogger.shared.logInfo("Error: \(rawCode) — session truly expired, prompting new session. msg: \(rawMsg)")
        await MainActor.run {
          lastSessionRecoveryReason = rawCode
          webSocketConnectionTitle = "Session expired"
          webSocketErrorMessage = "Session expired. Please start a new session."
          chatErrorState = .sessionExpired
        }
        
      case .invalidEvent, .invalidContentType:
        WebSocketLogger.shared.logInfo("Ignorable WS error — code: \(rawCode), msg: \(rawMsg)")
        print("⚠️ Ignorable WebSocket error (\(model.data?.code ?? ""))")
        
      case .parsingError:
        WebSocketLogger.shared.logInfo("Error: parsingError — code: \(rawCode), msg: \(rawMsg). Prompting retry...")
        await MainActor.run {
          lastSessionRecoveryReason = rawCode
          webSocketConnectionTitle = "Error parsing request"
          webSocketErrorMessage = "Something went wrong. Tap Retry to continue."
          chatErrorState = .connectionError
        }
        
      case .timeout:
        WebSocketLogger.shared.logInfo("Error: timeout — code: \(rawCode), msg: \(rawMsg). Prompting retry...")
        await MainActor.run {
          lastSessionRecoveryReason = rawCode
          webSocketConnectionTitle = "Request timed out"
          webSocketErrorMessage = "Request timed out. Tap Retry to continue."
          chatErrorState = .connectionError
        }
        
      case .promptFetchError, .invalidFileRequest, .serverError, .none:
        WebSocketLogger.shared.logInfo("Error: \(rawCode) — msg: \(rawMsg). Prompting retry...")
        await MainActor.run {
          lastSessionRecoveryReason = rawCode
          webSocketConnectionTitle = "Something went wrong"
          webSocketErrorMessage = "Something went wrong. Tap Retry to continue."
          chatErrorState = .connectionError
        }
      }

      
      await MainActor.run {
        if voiceProcessing || !messageInput {
          voiceProcessing = false
          messageInput = true
        }
      }
      
    case .chat:
      if model.contentType == .file,
         let urls = model.data?.urls, !urls.isEmpty {
        handleFileUploadResponse(urls: urls, requestId: model.id)
      }
      else if (model.contentType == .audioTranscript || model.contentType == .inlineText),
         let transcribedText = model.data?.text {
        await MainActor.run {
          self.inputString = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
          self.voiceProcessing = false
          self.messageInput = true
        }
      }
      
    case .eos:
      await DatabaseConfig.shared.upsertMessageV2(responseMessage: messageText, userChat: userMessage, suggestions: suggestions, multiSelect: multiSelect)
      await MainActor.run {
        messageText = ""
        streamStarted = false
        suggestions = nil
        multiSelect = nil
      }
      
    default:
      break
    }
  }
  
  // MARK: - Session Management
  
  public func createSession(
    subTitle: String?,
    oid: String = "",
    userDocId: String,
    userBId: String
  ) async -> String {
    
    await MainActor.run {
      initialMessageText = nil
      initialMessageSuggestions = nil
    }
    
    if let sessionId = await fetchExistingActiveSession(userDocId: userDocId, userBId: userBId) {
      return sessionId
    }
    
    return await createNewSession(subTitle: subTitle, oid: oid, userDocId: userDocId, userBId: userBId)
  }
  
  private func fetchExistingActiveSession(userDocId: String, userBId: String) async -> String? {
    // Always fetch from DB scoped to this user — never from UserDefaults,
    // which is shared across profiles and would return the wrong session.
    guard let dbSession = try? await DatabaseConfig.shared
      .fetchSessionIdwithoutoid(userDocId: userDocId, userBId: userBId)
      .last else {
      print("#BB fetchExistingActiveSession — no existing session found, will create new")
      return nil
    }

    let sessionId = dbSession.sessionId
    print("#BB fetchExistingActiveSession — found DB session: \(sessionId), validating with server...")

    // Fast path: connect immediately with cached token instead of waiting
    // for validation network call, which can delay auth by several seconds.
    let cachedToken = dbSession.sessionToken ?? ""
    print("#BB fetchExistingActiveSession — connecting immediately with cached token")
    activateSession(id: sessionId, token: cachedToken)
    Task {
      await webSocketAuthentication(sessionId: sessionId, sessionToken: cachedToken)
    }

    // Validate in background and adjust only if needed.
    Task { [weak self] in
      guard let self else { return }
      let statusResult = await checkSessionStatus(for: sessionId)
      switch statusResult {
      case .active:
        // Token may have been rotated on server; if changed, re-auth quickly.
        let latestToken = (try? await DatabaseConfig.shared.fetchSession(bySessionId: sessionId))?.sessionToken ?? cachedToken
        // Clear any stale error banner — the session is confirmed active.
        await MainActor.run {
          if self.chatErrorState != .none {
            self.chatErrorState = .none
            self.webSocketErrorMessage = nil
            self.lastSessionRecoveryReason = nil
          }
        }
        if !latestToken.isEmpty, latestToken != cachedToken {
          WebSocketLogger.shared.logInfo("Session validated active with rotated token — reconnecting with latest token")
          await webSocketAuthentication(sessionId: sessionId, sessionToken: latestToken)
        }
      case .expired:
        await MainActor.run {
          self.lastSessionRecoveryReason = "existing_session_expired"
          self.webSocketConnectionTitle = "Session expired"
          self.webSocketErrorMessage = "Session expired. Tap Retry to refresh."
          self.chatErrorState = .connectionError
        }
      case .networkError:
        break
      }
    }
    return sessionId
  }
  
  public func createNewSession(
    subTitle: String?,
    oid: String = "",
    userDocId: String,
    userBId: String
  ) async -> String {
    let requestModel = AuthSessionRequestModel(uerId: userDocId)

    // Bridge the callback API into async — resume immediately with the server response
    // (a value type), never inside a nested Task. Doing async DB/WebSocket work inside
    // the continuation's Task would violate the single-resume contract and lose actor context.
    typealias SessionResult = Result<(id: String, token: String, initialMessage: String?), Error>
    let serverResult: SessionResult = await withCheckedContinuation { continuation in
      MatrixApiService.shared.createSession(requestModel: requestModel) { result, _ in
        switch result {
        case .success(let sessionResponse):
          let text = sessionResponse.initialMessage?.text
          continuation.resume(returning: .success((
            id: sessionResponse.sessionID,
            token: sessionResponse.sessionToken,
            initialMessage: text
          )))
        case .failure(let error):
          continuation.resume(returning: .failure(error))
        }
      }
    }

    switch serverResult {
    case .failure(let error):
      print("Error creating session: \(error)")
      return ""
    case .success(let session):
      // All async work happens after the continuation has already resolved.
      let _ = await DatabaseConfig.shared.createSession(
        subTitle: subTitle,
        oid: oid,
        userDocId: userDocId,
        userBId: userBId,
        sessionId: session.id,
        sessionToken: session.token
      )
      activateSession(id: session.id, token: session.token)
      if let text = session.initialMessage {
        initialMessageText = text
      }
      await webSocketAuthentication(sessionId: session.id, sessionToken: session.token)
      return session.id
    }
  }
  
  private func activateSession(id: String, token: String) {
    switchToSession(id)
    isWebSocketSetupDone = true
  }
}

