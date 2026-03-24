//
//  MessageInputView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore

struct MessageInputView: View {
  @Binding var inputString: String
  @Binding var selectedImages: [String]
  @Binding var selectedDocumentId: [String]
  @Binding var showRecordsView: Bool
  @FocusState private var isTextFieldFocused: Bool
  let patientName: String?
  let viewModel: ChatViewModel
  let session: String
  let messages: [ChatMessageModel]
  let recordsRepo: RecordsRepo
  @State var showVoiceToRxPopUp: Bool = false
  @Binding var voiceToRxTip: VoiceToRxTip

  var body: some View {
    VStack(spacing: 0) {
      if !selectedImages.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(selectedImages.indices, id: \.self) { index in
              ImagePreviewCell(imageUrl: selectedImages[index], imageId: index) { id in
                selectedImages.remove(at: id)
              }
            }
          }
        }
        .frame(height: 20)
        .padding()
      }
            
      TextField("Message...", text: $inputString, axis: .vertical)
        .font(Font.custom("Lato-Regular", size: 16))
        .focused($isTextFieldFocused)
        .lineLimit(1...6)
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 16)

      HStack(spacing: 4) {
        Button {
          showMedicalRecords()
        } label: {
          Image(systemName: "paperclip")
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color.primaryprimary)
            .frame(width: 32, height: 32)
        }
        .fullScreenCover(isPresented: $showRecordsView) {
          NavigationStack {
            RecordContainerView(recordPresentationState: RecordPresentationState.picker(maxCount: 1), didSelectPickerDataObjects: { data in
              let images = data.compactMap { record in
                record.image
              }
              let docIds = data.compactMap { record in
                record.documentID
              }
              selectedImages = Array(images.prefix(3))
              selectedDocumentId = Array(docIds.prefix(3))
              showRecordsView = false
            })
          }
        }
        
        Spacer()
        microphoneButton
        sendOrStopButton
      }
      .padding(.horizontal, 8)
      .padding(.bottom, 6)
    }
    .background(Color.clear)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24)
        .stroke(Color(red: 0.83, green: 0.87, blue: 1), lineWidth: 1)
    )
    .padding(.horizontal, 16)
    .padding(.vertical, 6)
    .onAppear {
      guard let type = viewModel.openType else { return }
      if type == "chat" {
        isTextFieldFocused = true
      } else if type == "voiceToText" {
        startVoiceToText()
      }
      viewModel.openType = nil
    }
  }

  // MARK: - Buttons

  @ViewBuilder
  private var sendOrStopButton: some View {
    if viewModel.streamStarted {
      stopButton
    } else {
      sendButton
    }
  }

  var microphoneButton: some View {
    Button {
      startVoiceToText()
    } label: {
      Image(systemName: "mic.fill")
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color.primaryprimary)
        .frame(width: 36, height: 36)
    }
  }

  var sendButton: some View {
    Button {
      inputString = inputString.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !inputString.isEmpty else { return }
      Task {
        await viewModel.sendMessage(
          newMessage: inputString,
          imageUrls: selectedImages,
          vaultFiles: selectedDocumentId,
          sessionId: session,
          lastMesssageId: messages.last?.msgId
        )
        inputString = ""
        selectedImages = []
        selectedDocumentId = []
        DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "send"])
        isTextFieldFocused.toggle()
      }
    } label: {
      Image(systemName: "arrow.up.circle.fill")
        .resizable()
        .scaledToFit()
        .frame(width: 30, height: 30)
        .foregroundStyle(
          inputString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.streamStarted
            ? Color.gray.opacity(0.5)
            : Color.primaryprimary
        )
        .frame(width: 36, height: 36)
    }
    .disabled(inputString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.streamStarted)
  }

  var stopButton: some View {
    Button {
      viewModel.stopStreaming()
    } label: {
      Image(systemName: "stop.circle")
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .foregroundColor(Color(red: 0.84, green: 0.29, blue: 0.26))
        .padding(4)
    }
  }

  // MARK: - Helpers

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
  
  private func startVoiceToText() {
    AudioPermissionManager.shared.checkAndRequestMicrophonePermission {
      viewModel.messageInput = false
      viewModel.startRecording()
    }
    DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "voicetx"])
  }
}

struct VoiceInputView: View {
  var viewModel: ChatViewModel
  
  var body: some View {
    HStack(alignment: .center, spacing: 10) {
      Button {
        viewModel.dontRecord()
      } label: {
        Image(systemName: "xmark")
          .frame(width: 24, height: 24)
          .padding(6)
      }
      .frame(width: 36, height: 36)
      .background(Color.white)
      .cornerRadius(18)
      
      if viewModel.isRecording {
        AudioWaveformView()
          .frame(height: 36)
          .layoutPriority(1)
      } else {
        Text("Converting to text...")
      }
      
      TimerView(isTimerRunning: !viewModel.voiceProcessing)
        .frame(width: 60)
      
      if viewModel.voiceProcessing {
        ProgressView()
          .frame(width: 36, height: 36)
      }
      
      if !viewModel.voiceProcessing {
        Button {
          viewModel.stopRecording()
        } label: {
          Image(systemName: "checkmark")
            .frame(width: 24, height: 24)
            .padding(6)
        }
        .frame(width: 36, height: 36)
        .background(Color.white)
        .cornerRadius(18)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 44)
    .padding(.horizontal, 8)
    .background(Color.white)
    .cornerRadius(16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .inset(by: -0.5)
        .stroke(Color(red: 0.83, green: 0.87, blue: 1), lineWidth: 1)
    )
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}
