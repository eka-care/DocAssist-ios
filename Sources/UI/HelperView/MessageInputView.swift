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
  @Binding var selectedDocumentId: [String]
  @Binding var showRecordsView: Bool
  @FocusState private var isTextFieldFocused: Bool
  let patientName: String?
  let viewModel: ChatViewModel
  let session: String
  let messages: [ChatMessageModel]
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let recordsRepo: RecordsRepo
  var liveActivityDelegate: LiveActivityDelegate?
  @State var showVoiceToRxPopUp: Bool = false
  @Binding var voiceToRxTip: VoiceToRxTip
    
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
      
      HStack(spacing: 12) {
          Button {
            showRecordsView = true
            DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "records"])
            if patientName != "General Chat" {
              InitConfiguration.shared.recordsTitle = "\(patientName ?? "")'s Records"
            } else {
              InitConfiguration.shared.recordsTitle = "My documents"
            }
          } label: {
            Image(.paperClip)
              .resizable()
              .scaledToFit()
              .frame(width: 16)
              .foregroundStyle(Color.neutrals600)
          }
          .sheet(isPresented: $showRecordsView) {
            NavigationStack {
              RecordsView(recordsRepo: recordsRepo, recordPresentationState: .picker) { data in
                
                let images = data.compactMap { record in
                  record.image
                }
                let docIds = data.compactMap { record in
                  record.documentID
                }
                
                selectedImages = Array(images.prefix(3))
                selectedDocumentId = Array(docIds.prefix(3))
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
        
        // Hide microphone button for patient app
          Button {
            viewModel.handleMicrophoneTap()
            DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPgClick, properties: ["type": "voicetx"])
          } label: {
            Image(.mic)
              .resizable()
              .scaledToFit()
              .frame(width: 16)
              .foregroundStyle(Color.neutrals600)
          }
          .disabled(!viewModel.v2rxEnabled)
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
        
        // Send button
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
            isTextFieldFocused.toggle()
          }
        } label: {
          Image(systemName: "arrow.up.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 30,height: 30)
            .foregroundStyle((inputString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImages.isEmpty) || viewModel.streamStarted ? Color.gray.opacity(0.5) : Color.primaryprimary)
            .frame(width: 36,height: 36)
        }
        .disabled((inputString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImages.isEmpty) || viewModel.streamStarted)
        
        // Voice to Rx button - only show for non-patient app
        if let isPatient = SetUIComponents.shared.isPatientApp, !isPatient, viewModel.streamStarted {
          Button {
            viewModel.stopStreaming()
            viewModel.stopFirestoreStream()
          } label: {
            Image(systemName: "stop.circle")
              .resizable()
              .scaledToFit()
              .frame(width: 24,height: 24)
              .foregroundColor(Color(red: 0.84, green: 0.29, blue: 0.26))
              .padding(4)
          }
        } else if let isPatient = SetUIComponents.shared.isPatientApp, !isPatient, inputString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Button {
            showVoiceToRxPopUp = true
            Task {
              await VoiceToRxTip.voiceToRxVisited.donate()
            }
            voiceToRxTip.invalidate(reason: .actionPerformed)
          } label: {
            Image(systemName: "waveform.circle.fill")
              .resizable()
              .scaledToFit()
              .frame(width: 30,height: 30)
              .foregroundStyle(viewModel.v2rxEnabled ? LinearGradient(
                stops: [
                  Gradient.Stop(color: Color(red: 0.13, green: 0.36, blue: 1), location: 0.00),
                  Gradient.Stop(color: Color(red: 0.68, green: 0.44, blue: 0.82), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0, y: 0.5),
                endPoint: UnitPoint(x: 1, y: 0.5)
              ) : LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
              )
              )
              .frame(width: 36,height: 36)
          }
          .popoverTip(voiceToRxTip, arrowEdge: .bottom)
          .disabled(!viewModel.v2rxEnabled)
          .sheet(isPresented: $showVoiceToRxPopUp) {
            VoiceToRxPopUpView(
              viewModel: viewModel,
              session: session,
              voiceToRxViewModel: voiceToRxViewModel,
              messages: messages,
              startVoicetoRx: $showVoiceToRxPopUp
            )
            .presentationDetents([.height(400)])
          }
        }
      }
    }
    .focused($isTextFieldFocused)
    .padding(16)
    .background(Color(.white))
    .customCornerBorder(20, corners: [.topLeft, .topRight], color: Color.gray, lineWidth: 0.5)
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
