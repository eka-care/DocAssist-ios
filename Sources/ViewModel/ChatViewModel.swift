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
    openType: String? = nil
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
  
  private func streamReply(to userMessageId: String, sessionId: String, text: String, documentPaths: [String]?) {
    DispatchQueue.main.async { [weak self] in
      self?.streamStarted = true
    }
    
    streamTask?.cancel()
    streamTask = Task { [weak self] in
      let files = MatrixUploadFile.load(paths: documentPaths ?? [])
      let stream = MatrixClient.shared.chat(localSessionId: sessionId, text: text, files: files)
      var answer = ""
      var suggestions: [String]?
      do {
        for try await event in stream {
          switch event {
          case .chunk(let text):
            answer += text
          case .tips(let tips):
            suggestions = tips
          case .progress:
            continue
          }
          await ChatStore.shared.upsertReply(to: userMessageId, sessionId: sessionId, text: answer, suggestions: suggestions)
        }
      } catch is CancellationError {
      } catch {
        print("#Matrix stream failed: \(error)")
        if answer.isEmpty, !Task.isCancelled {
          let message = (error as? MatrixError)?.errorDescription ?? "Something went wrong. Please try again."
          await ChatStore.shared.upsertReply(to: userMessageId, sessionId: sessionId, text: message, suggestions: nil)
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
