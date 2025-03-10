//
//  SwiftUIView.swift
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
  @Binding var selectedDocumentId: [String]
  @Binding var showRecordsView: Bool
  @FocusState private var isTextFieldFocused: Bool
  let patientName: String?
  let viewModel: ChatViewModel
  let session: String
  let messages: [ChatMessageModel]
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let recordsRepo: RecordsRepo
  
  var body: some View {
    VStack(spacing: 15) {
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
      
      TextField("Start typing...", text: $inputString, axis: .vertical)
        .frame(minHeight: 25)
      
      HStack(spacing: 10) {
        Button {
          showRecordsView = true
          DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "records"])
        } label: {
          Image(.paperClip)
            .foregroundStyle(Color.neutrals600)
        }
        .sheet(isPresented: $showRecordsView) {
          NavigationStack {
            RecordsView(recordsRepo: recordsRepo, recordPresentationState: .picker) { data in
              selectedImages = data.compactMap { record in
                record.image
              }
              selectedDocumentId = data.compactMap { record in
                record.documentID
              }
              showRecordsView = false
            }
            .environment(\.managedObjectContext, recordsRepo.databaseManager.container.viewContext)
          }
        }
        
        if let patientName = patientName, !patientName.isEmpty, patientName != "General Chat" {
          HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .center, spacing: 10) {
              Image(systemName: "person.fill")
            }
            .padding(4)
            .frame(width: 16, height: 16, alignment: .center)
            
            Text(patientName)
              .font(Font.custom("Lato-Bold", size: 12))
              .foregroundColor(Color(red: 0.28, green: 0.28, blue: 0.28))
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(Color(red: 0.91, green: 0.91, blue: 0.91))
          .cornerRadius(123)
        }
        
        Spacer()
        
        Button {
          viewModel.handleMicrophoneTap()
          DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "voicetx"])
        } label: {
          Image(.mic)
            .resizable()
            .scaledToFit()
            .frame(width: 14)
            .foregroundStyle(Color.neutrals600)
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
        
        if !inputString.isEmpty {
          Button {
            inputString = inputString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !inputString.isEmpty || !selectedImages.isEmpty else { return }
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
            }
          } label: {
            Image(systemName: "arrow.up")
              .foregroundStyle(Color.white)
              .fontWeight(.semibold)
              .padding(4)
              .background((inputString.isEmpty || viewModel.streamStarted) ? Circle().fill(Color.gray.opacity(0.5)) : Circle().fill(Color.primaryprimary))
          }
          .disabled(inputString.isEmpty || viewModel.streamStarted)
        } else {
          Menu {
            Button {
              voiceToRxViewModel.startRecording(conversationType: .dictation)
              FloatingVoiceToRxViewController.shared.showFloatingButton(viewModel: voiceToRxViewModel)
              Task {
                guard let v2RxSessionId = voiceToRxViewModel.sessionID else { return }
                let v2rxAudioFileString = await viewModel.fetchVoiceConversations(using: v2RxSessionId)
                let _ = await DatabaseConfig.shared.createMessage(sessionId: session, messageId: (messages.last?.msgId ?? 0) + 1 , role: .Bot, imageUrls: nil, v2RxAudioSessionId: v2RxSessionId, v2RxaudioFileString: v2rxAudioFileString)
              }
            } label: {
              Image(.micMenu)
              Text("Dictation mode")
                .font(Font.custom("Lato-Regular", size: 14))
                .foregroundStyle(Color.neutrals400)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button {
              voiceToRxViewModel.startRecording(conversationType: .conversation)
              FloatingVoiceToRxViewController.shared.showFloatingButton(viewModel: voiceToRxViewModel)
              Task {
                guard let v2RxSessionId = voiceToRxViewModel.sessionID else { return }
                let v2rxAudioFileString = await viewModel.fetchVoiceConversations(using: v2RxSessionId)
                let _ = await DatabaseConfig.shared.createMessage(sessionId: session, messageId: (messages.last?.msgId ?? 0) + 1 , role: .Bot, imageUrls: nil, v2RxAudioSessionId: v2RxSessionId, v2RxaudioFileString: v2rxAudioFileString)
              }
            } label: {
              Image(.v2RxMenu)
              Text("Conversation mode")
                .font(Font.custom("Lato-Regular", size: 14))
                .foregroundStyle(Color.neutrals400)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          } label: {
            Image(.voiceToRxButton)
              .padding(4)
          }
        }
      }
    }
    .focused($isTextFieldFocused)
    .padding(8)
    .background(Color(.white))
    .cornerRadius(20)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(Color.gray, lineWidth: 0.5)
    )
    .padding(8)
    .onAppear {
      setupFloatingVoiceToRxController()
    }
  }
}

extension MessageInputView {
  private func setupFloatingVoiceToRxController() {
    FloatingVoiceToRxViewController.shared.voiceToRxDelegate = V2RxInitConfigurations.shared.voiceToRxDelegate
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
                Spacer()
                    .frame(height: 36)
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
