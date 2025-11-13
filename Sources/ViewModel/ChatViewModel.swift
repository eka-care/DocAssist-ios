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
  
  func startStreamingPostRequest(vaultFiles: [String]?, userChat: ChatMessageModel?) {
    guard let userChat else { return }
    
    ///Firestore handling
    let ownerId = userDocId + "_" + userBid
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
//    await MainActor.run {
//      Task {
//          await DatabaseConfig.shared.upsertMessageV2(responseMessage: message?.text ?? "", userChat: userChat, suggestions: message?.suggestions)
//      }
//    }
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
    delegate?.convertVoiceToText(audioFileURL:  currentRecording, completion: { [weak self] result in
      guard let self = self else { return }
      self.voiceProcessing = false
      self.messageInput = true
      switch result {
        case .success(let transcribedText):
          self.inputString = transcribedText

        case .failure(let error):
          self.alertTitle = "Transcription Failed"
          self.alertMessage = error.localizedDescription
          self.showTranscriptionFailureAlert = true
        }
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

extension ChatViewModel {
  func navigateToDeepThought(id: String?) {
    guard let id else { return }
    deepThoughtNavigationDelegate?.navigateToDeepThoughtPage(id: id)
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

// MARK: - Web Socket flow
extension ChatViewModel {
  
  func checkandValidateWebSocketConnection() async {
    guard let url = URL(string: "https://matrix.dev.eka.care/med-assist/session") else { return }
    
    do {
      let requestBody = try JSONEncoder().encode(AuthSessionRequestModel(uerId: userDocId))
      
      let networkRequest = HTTPNetworkRequest(
        url: url,
        method: .post,
        headers: ["Content-Type": "application/json", "x-agent-id": "NDBkNmM4OTEtNGEzMC00MDBlLWE4NjEtN2ZkYjliMDY2MDZhI2VrYV9waHI="],
        body: requestBody
      )
      
      networkRequest.execute { [weak self] result in
        guard let self else { return }
        switch result {
        case .success(let data):
          do {
            let decoder = JSONDecoder()
            let sessionModel = try decoder.decode(AuthSessionResponseModel.self, from: data)
            print("✅ #BB Session model:", sessionModel)
            Task {
              await self.webSocketAuthentication(sessionId: sessionModel.sessionID, sessionToken: sessionModel.sessionToken)
            }
          } catch {
            print("❌ #BB JSON decode error:", error)
          }
          
        case .failure(let error):
          print("❌ #BB Network error:", error.localizedDescription)
        }
      }
    } catch {
      print("❌ #BB Encoding error:", error)
    }
  }
  
  func checkIfSessionIsActive(for sessionId: String) async {
    guard let url = URL(string: "https://matrix.dev.eka.care/med-assist/session/\(sessionId)") else { return }
    
    let networkRequest = HTTPNetworkRequest(
      url: url,
      method: .get,
      headers: ["Content-Type": "application/json", "x-agent-id": "NDBkNmM4OTEtNGEzMC00MDBlLWE4NjEtN2ZkYjliMDY2MDZhI2VrYV9waHI="],
      body: nil
    )
    
    networkRequest.execute { result in
      switch result {
      case .success(let data):
        print("#BB Data:", String(data: data, encoding: .utf8)!)
      case .failure(let error):
        print("#BB failure error:", error.localizedDescription)
      }
    }
  }
  
  func refreshSession(for sessionId: String) async {
    guard let url = URL(string: "https://matrix.dev.eka.care/med-assist/session/\(sessionId)/refresh") else  {
      return
    }
    
    let networkRequest = HTTPNetworkRequest(
      url: url,
      method: .post,
      headers: ["Content-Type": "application/json", "x-agent-id": "NDBkNmM4OTEtNGEzMC00MDBlLWE4NjEtN2ZkYjliMDY2MDZhI2VrYV9waHI="],
      body: nil
    )
    
    networkRequest.execute { result in
      switch result {
      case .success(let data):
        print("#BB Data:", String(data: data, encoding: .utf8)!)
      case .failure(let error):
        print("#BB failure error:", error.localizedDescription)
      }
    }
  }
  
  func webSocketAuthentication(sessionId: String, sessionToken: String) async {
    guard let url = URL(string: "wss://matrix-ws.dev.eka.care/ws/med-assist/session/\(sessionId)/") else {
      print("❌ Invalid WebSocket URL")
      return
    }
    
    webSocketClient = WebSocketNetworkRequest(url: url)
    webSocketClient?.onMessageDecoded = { [weak self] model in
        Task { await self?.handleWebSocketModel(model) }
    }
    webSocketClient?.connect { connected in
      guard connected else {
        print("❌ WebSocket connection failed")
        return
      }
      
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
          self.webSocketClient?.send(message: jsonString)
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
          ev: .chat,
          ts: timestamp,
          id: String(timestamp),
          ct: .text,
          msg: nil,
          data: data
      )

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
          switch model.ev {
          case .stream:
              if let text = model.data?.text {
                     // self.resultvalue += text
                //    await MainActor.run {
                
                      Task {
                        print("#BB text is \(text)")
                        await DatabaseConfig.shared.upsertMessageV2(responseMessage: text, userChat: userMessage, suggestions: nil)
                      }
               //     }
                      print("🧩 Stream text appended: \(text)")
                  
                   
              } else if let progress = model.data?.text ?? model.data?.audio {
                  DispatchQueue.main.async {
                  //    self.resultvalue = progress
                      print("⏳ Progress: \(progress)")
                  }
              }

          case .eos:
              DispatchQueue.main.async {
                  print("✅ Stream ended.")
              }

          case .err:
              print("⚠️ WebSocket error event: \(model.msg ?? "Unknown error")")

          default:
              break
          }
      }
}

