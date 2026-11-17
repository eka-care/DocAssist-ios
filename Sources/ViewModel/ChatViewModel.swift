//
//  ChatViewModel.swift
//  Chatbot
//
//  Created by Brunda B on 12/11/24.
//

import SwiftUI
import AVFAudio
import AVFoundation
import EkaVoiceToRx
import FirebaseFirestore

@Observable
public final class ChatViewModel: NSObject, URLSessionDataDelegate {
  
  /// Constant Strings
  private let role = "user"
  private let userAgent = "d-iOS"
  private var firestoreListener: ListenerRegistration?
  
  var streamStarted: Bool = false
  
  private(set) var vmssid: String = ""
  private var delegate: ConvertVoiceToText? = nil
  private var deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil
  var liveActivityDelegate: LiveActivityDelegate? = nil
  var suggestionsDelegate: GetMoreSuggestions? = nil
  var getPatientDetailsDelegate: GetPatientDetails? = nil
  
  private var streamTask: Task<Void, Never>?
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
  var showTranscriptionFailureAlert = false
  var openType: String?
  /// Sent once when the chat opens, e.g. a question typed on the host app's home screen.
  var initialMessage: String?
  /// The last reply that failed (offline, timeout, auth, server). Shown under the
  /// question with a Retry button; never written into the chat as an answer.
  private(set) var failedReply: FailedReply?
  private let failureLogger = AskAIFailureLogger()
  
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
    delegate: ConvertVoiceToText? = nil,
    deepThoughtNavigationDelegate: DeepThoughtsViewDelegate? = nil,
    liveActivityDelegate: LiveActivityDelegate? = nil,
    userBid: String,
    userDocId: String,
    patientName: String = "",
    suggestionsDelegate: GetMoreSuggestions? = nil,
    getPatientDetailsDelegate: GetPatientDetails? = nil,
    openType: String? = nil,
    initialMessage: String? = nil
  ) {
    self.delegate = delegate
    self.deepThoughtNavigationDelegate = deepThoughtNavigationDelegate
    self.liveActivityDelegate = liveActivityDelegate
    self.userBid = userBid
    self.userDocId = userDocId
    self.patientName = patientName
    self.suggestionsDelegate = suggestionsDelegate
    self.getPatientDetailsDelegate = getPatientDetailsDelegate
    self.openType = openType
    self.initialMessage = initialMessage
  }
  
  /// Saves the doctor's message, then streams the answer from Matrix into the chat.
  func sendMessage(
    newMessage: String,
    imageUrls: [String]?,
    documentPaths: [String]?,
    sessionId: String
  ) async {
    let userMessageId = await ChatStore.shared.appendUserMessage(
      sessionId: sessionId,
      text: newMessage,
      imageUrls: imageUrls
    )
    streamReply(
      to: userMessageId,
      sessionId: sessionId,
      text: newMessage,
      documentPaths: documentPaths
    )
  }
  
  /// Sends the failed question again and streams its answer into the same reply.
  func retryFailedReply() {
    guard let failed = failedReply else { return }
    streamReply(
      to: failed.userMessageId,
      sessionId: failed.sessionId,
      text: failed.text,
      documentPaths: failed.documentPaths,
      isRetry: true
    )
  }

  private func streamReply(
    to userMessageId: String,
    sessionId: String,
    text: String,
    documentPaths: [String]?,
    isRetry: Bool = false
  ) {
    DispatchQueue.main.async { [weak self] in
      self?.failedReply = nil
      self?.streamStarted = true
    }
    
    streamTask?.cancel()
    let failureLogger = failureLogger
    streamTask = Task { [weak self] in
      let loaded = MatrixUploadFile.load(paths: documentPaths ?? [])
      let files = loaded.files
      let stream = MatrixClient.shared.chat(localSessionId: sessionId, text: text, files: files)
      var attempt = AskAIChatAttempt(
        chatId: sessionId,
        messageId: userMessageId,
        isRetry: isRetry,
        text: text,
        documentPaths: documentPaths,
        loaded: loaded
      )
      var answer = ""
      var suggestions: [String]?
      do {
        for try await event in stream {
          attempt.record(event)
          switch event {
          case .chunk(let text):
            answer += text
          case .tips(let tips):
            suggestions = tips
          case .progress, .upload:
            continue
          }
          await ChatStore.shared.upsertReply(to: userMessageId, sessionId: sessionId, text: answer, suggestions: suggestions)
        }
        failureLogger.finish(attempt, result: Task.isCancelled ? .stopped : .answered)
      } catch is CancellationError {
        failureLogger.finish(attempt, result: .stopped)
      } catch {
        print("#Matrix stream failed: \(error)")
        if Task.isCancelled {
          failureLogger.finish(attempt, result: .stopped)
        } else {
          failureLogger.finish(attempt, result: .failed(MatrixError.from(error)))
          let failure = FailedReply(
            userMessageId: userMessageId,
            sessionId: sessionId,
            text: text,
            documentPaths: documentPaths,
            error: MatrixError.from(error),
            isPartial: !answer.isEmpty
          )
          await MainActor.run { [weak self] in
            self?.failedReply = failure
          }
        }
      }
      await MainActor.run { [weak self] in
        self?.streamStarted = false
      }
    }
  }
  
  func isSessionsPresent(oid: String, userDocId: String, userBId: String) async -> Bool {
    await ChatStore.shared.hasSessions(patientOid: oid, doctorOid: userDocId, businessId: userBId)
  }
  
  public func createSession(subTitle: String?, oid: String = "", userDocId: String, userBId: String) async -> String {
    let session = await ChatStore.shared.createSession(
      doctorOid: userDocId,
      businessId: userBId,
      patientOid: oid,
      patientName: subTitle
    )
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
    streamTask?.cancel()
    streamTask = nil
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
      NetworkConfig.shared.sessionContext["pt_oid"] = oid
  }
}

/// A question whose answer did not arrive (or stopped part way).
struct FailedReply {
  let userMessageId: String
  let sessionId: String
  let text: String
  let documentPaths: [String]?
  let error: MatrixError
  let isPartial: Bool

  var title: String {
    switch error {
    case .offline: "No internet connection"
    case .authExpired, .authRejected: "Couldn't verify your account"
    case .serviceUnavailable: "Ask AI is unavailable"
    case .fileUploadFailed, .filesNotAttached: "Your files weren't attached"
    default: isPartial ? "The answer was interrupted" : "Couldn't get an answer"
    }
  }

  var message: String {
    error.errorDescription ?? "Something went wrong. Please try again."
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
