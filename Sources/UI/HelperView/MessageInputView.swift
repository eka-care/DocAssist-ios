//
//  MessageInputView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore
import EkaVoiceToRx

struct MessageInputView: View {
  @Binding var inputString: String
  @Binding var selectedImages: [String]
  @Binding var selectedDocumentPaths: [String]
  @Binding var showRecordsView: Bool
  let patientName: String?
  let viewModel: ChatViewModel
  let session: String
  let messages: [ChatMessage]
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let recordsRepo: RecordsRepo
  var liveActivityDelegate: LiveActivityDelegate?
  @State var showVoiceToRxPopUp: Bool = false
  @Binding var voiceToRxTip: VoiceToRxTip
  /// Owned by the chat screen, so it can scroll to the latest message when the keyboard opens.
  var isTextFieldFocused: FocusState<Bool>.Binding
  
  /// Bumped on every send; drives the send haptic.
  @State private var sendCount = 0
  
  private var trimmedInput: String {
    inputString.trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
  private var hasAttachments: Bool {
    !selectedImages.isEmpty || !selectedDocumentPaths.isEmpty
  }
  
  private var canSend: Bool {
    (!trimmedInput.isEmpty || hasAttachments) && !viewModel.streamStarted
  }
  
  private var patientChipName: String? {
    guard let patientName, !patientName.isEmpty, patientName != "General Chat" else { return nil }
    return patientName
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if patientChipName != nil || hasAttachments {
        contextRow
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
      
      ChatGlassContainer(spacing: 10) {
        HStack(alignment: .bottom, spacing: 10) {
          attachButton
          composerField
          if viewModel.streamStarted {
            stopButton
              .transition(.scale.combined(with: .opacity))
          } else if canSend {
            sendButton
              .transition(.scale.combined(with: .opacity))
          }
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.top, 6)
    .padding(.bottom, 8)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canSend)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.streamStarted)
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasAttachments)
    .sensoryFeedback(.impact(weight: .light), trigger: sendCount)
    .fullScreenCover(isPresented: $showRecordsView) {
      NavigationStack {
        RecordContainerView(recordPresentationState: RecordPresentationState.picker(maxCount: 5), didSelectPickerDataObjects: { data in
          let images = data.compactMap { record in
            record.image
          }
          let documentPaths = data.flatMap { record in
            record.documentPath ?? []
          }
          selectedImages = Array(images.prefix(3))
          selectedDocumentPaths = Array(documentPaths.prefix(3))
          showRecordsView = false
        })
      }
    }
    .alert(isPresented: viewModel.showPermissionAlertBinding) {
      Alert(
        title: Text(viewModel.alertTitle),
        message: Text(viewModel.alertMessage),
        primaryButton: .default(Text("Go to Settings")) {
          viewModel.openAppSettings()
        },
        secondaryButton: .cancel(Text("Cancel"))
      )
    }
    .onAppear {
      guard let type = viewModel.openType else { return }
      if type == "EkaScribe" {
        startVoiceToRx()
      } else if type == "MedicalRecords" {
        showMedicalRecords()
      } else if type == "chat" {
        isTextFieldFocused.wrappedValue = true
      } else if type == "voiceToText" {
        startVoiceToText()
      }
      
      viewModel.openType = nil 
    }
  }
  
  // MARK: - Composer parts
  
  /// Patient the chat is about, and the files that will go with the next message.
  private var contextRow: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        if let patientChipName {
          Label(patientChipName, systemImage: "person.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .chatGlass(in: Capsule(), interactive: false)
        }
        
        ForEach(selectedImages.indices, id: \.self) { index in
          ImagePreviewCell(imageUrl: selectedImages[index], imageId: index) { id in
            selectedImages.remove(at: id)
          }
        }
        
        if selectedImages.isEmpty, !selectedDocumentPaths.isEmpty {
          Label("\(selectedDocumentPaths.count) document\(selectedDocumentPaths.count == 1 ? "" : "s")", systemImage: "doc.fill")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .chatGlass(in: Capsule(), interactive: false)
        }
      }
      .padding(.horizontal, 4)
      .padding(.vertical, 2)
    }
  }
  
  private var attachButton: some View {
    Button {
      showMedicalRecords()
    } label: {
      Image(systemName: "plus")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(.primary)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .chatGlass(in: Circle())
    .accessibilityLabel("Attach records")
  }
  
  /// Grows up to six lines; the mic sits inside while there is nothing to send.
  private var composerField: some View {
    HStack(alignment: .bottom, spacing: 4) {
      TextField("Ask DocAssist", text: $inputString, axis: .vertical)
        .font(.body)
        .lineLimit(1...6)
        .focused(isTextFieldFocused)
        .padding(.vertical, 11)
        .padding(.leading, 16)
        .padding(.trailing, canSend ? 16 : 0)
      
      if !canSend, !viewModel.streamStarted {
        Button {
          startVoiceToText()
        } label: {
          Image(systemName: "mic.fill")
            .font(.system(size: 17))
            .foregroundStyle(viewModel.v2rxEnabled ? Color.secondary : Color.secondary.opacity(0.4))
            .frame(width: 40, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.v2rxEnabled)
        .accessibilityLabel("Dictate")
        .transition(.opacity)
      }
    }
    .frame(minHeight: 44)
    .chatGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
  }
  
  private var sendButton: some View {
    Button(action: send) {
      Image(systemName: "arrow.up")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .chatGlass(in: Circle(), tint: Color.primaryprimary)
    .keyboardShortcut(.return, modifiers: .command)
    .accessibilityLabel("Send")
  }
  
  private var stopButton: some View {
    Button {
      viewModel.stopStreaming()
      viewModel.stopFirestoreStream()
    } label: {
      Image(systemName: "stop.fill")
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(.white)
        .frame(width: 44, height: 44)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .chatGlass(in: Circle(), tint: Color(.label).opacity(0.85))
    .accessibilityLabel("Stop generating")
  }
  
  /// Clears the composer right away and keeps the keyboard up, like Messages.
  private func send() {
    guard canSend else { return }
    let text = trimmedInput
    let images = selectedImages
    let documents = selectedDocumentPaths
    inputString = ""
    selectedImages = []
    selectedDocumentPaths = []
    sendCount += 1
    DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "send"])
    Task {
      await viewModel.sendMessage(
        newMessage: text,
        imageUrls: images.isEmpty ? nil : images,
        documentPaths: documents,
        sessionId: session
      )
    }
  }
  
  private func showMedicalRecords() {
      showRecordsView = true
      DocAssistEventManager.shared.trackEvent(
          event: .docAssistLandingPgClick,
          properties: ["type": "records"]
      )
      if patientName != "General Chat" {
          InitConfiguration.shared.recordsTitle = "\(patientName ?? "")'s Records"
      } else {
          InitConfiguration.shared.recordsTitle = "My documents"
      }
  }
  
  private func startVoiceToRx() {
    AudioPermissionManager.shared.checkAndRequestMicrophonePermission {
      showVoiceToRxPopUp = true
      Task {
        await VoiceToRxTip.voiceToRxVisited.donate()
      }
      voiceToRxTip.invalidate(reason: .actionPerformed)
    }
  }
  
  private func startVoiceToText() {
    AudioPermissionManager.shared.checkAndRequestMicrophonePermission {
      viewModel.messageInput = false
      viewModel.startRecording()
    }
    DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "voicetx"])
  }
}

/// Shown while dictating: cancel, live waveform with timer, and confirm, in the same glass as the composer.
struct VoiceInputView: View {
  var viewModel: ChatViewModel
  
  var body: some View {
    ChatGlassContainer(spacing: 10) {
      HStack(alignment: .center, spacing: 10) {
        Button {
          viewModel.dontRecord()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .chatGlass(in: Circle())
        .accessibilityLabel("Cancel dictation")
        
        HStack(spacing: 8) {
          if viewModel.isRecording {
            AudioWaveformView()
              .frame(height: 28)
              .layoutPriority(1)
          } else {
            Spacer()
          }
          TimerView(isTimerRunning: !viewModel.voiceProcessing)
            .font(.subheadline.monospacedDigit())
            .foregroundStyle(.secondary)
            .frame(width: 56)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 44)
        .chatGlass(in: Capsule(), interactive: false)
        
        Group {
          if viewModel.voiceProcessing {
            ProgressView()
              .frame(width: 44, height: 44)
              .chatGlass(in: Circle(), interactive: false)
          } else {
            Button {
              viewModel.stopRecording()
            } label: {
              Image(systemName: "checkmark")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .chatGlass(in: Circle(), tint: Color.primaryprimary)
            .accessibilityLabel("Finish dictation")
          }
        }
        .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.voiceProcessing)
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
  }
}
