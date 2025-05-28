//
//  SwiftUIView.swift
//  DocAssist-ios
//
//  Created by Brunda B on 16/05/25.
//

import SwiftUI
import EkaVoiceToRx

enum VoiceToRxMethodType: CaseIterable {
  case conversation
  case dictation
}

struct VoiceToRxPopUpView: View {
  
  private let title = "Use DocAssist AI to create medical documents."
  private let infoImage = "info.circle.fill"
  private let infoText = "By continuing, you acknowledge that patient consent was taken for AI-assisted scribing. All notes must still be reviewed and approved by you before saving"
  let viewModel: ChatViewModel
  let session: String
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let messages: [ChatMessageModel]
  @Binding var startVoicetoRx: Bool
  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.custom("Lato-Regular", size: 24))
        .multilineTextAlignment(.leading)
        .foregroundStyle(Color.neutrals1000)
        .padding(.bottom, 8)
      
      ForEach(Array(VoiceToRxMethodType.allCases.enumerated()), id: \.element) { index, type in
        VoiceToRxMethodView(
          voiceType: type,
          viewModel: viewModel,
          session: session,
          voiceToRxViewModel: voiceToRxViewModel,
          messages: messages,
          startVoicetoRx: $startVoicetoRx
        )
        .padding(.top, 16)
        if index < VoiceToRxMethodType.allCases.count - 1 {
          Divider()
        }
      }
      
      HStack {
          Image(systemName: infoImage)
            .resizable()
            .scaledToFit()
            .frame(width: 14)
            .foregroundStyle(Color.neutrals400)
            .multilineTextAlignment(.center)
        Text(infoText)
          .font(.custom("Lato-Regular", size: 12))
          .italic()
          .foregroundStyle(Color.neutrals400)
        
      }
    }
    .padding()
  }
}

struct VoiceToRxMethodView: View {
  var voiceType: VoiceToRxMethodType
  var viewModel: ChatViewModel
  var session: String
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let messages: [ChatMessageModel]
  @Binding var startVoicetoRx: Bool
  
  var title: String {
    switch voiceType {
    case .conversation:
      return "Conversation mode"
    case .dictation:
      return "Dictation mode"
    }
  }
  
  var subTitle: String {
    switch voiceType {
    case .conversation:
      return "DocAssist will listen to your conversation and create a medical document."
    case .dictation:
      return "Dictate your notes to DocAssist and create clinical notes."
    }
  }
  
  var image: UIImage {
    switch voiceType {
    case .conversation:
      return UIImage(resource: .conversationMenu)
    case .dictation:
      return UIImage(resource: .dictationMenu)
    }
  }
  
  var conversationType: VoiceConversationType {
    switch voiceType {
    case .conversation:
      return .conversation
    case .dictation:
      return .dictation
    }
  }
  var body: some View {
    HStack (alignment: .center) {
      VStack (alignment: .leading){
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(width: 40)
          .padding(.all, 4)
        Spacer()
      }
      
      VStack(alignment: .leading) {
        Text(title)
          .font(.custom("Lato-Bold", size: 18))
          .foregroundStyle(Color.neutrals1000)
          .multilineTextAlignment(.leading)
        Text(subTitle)
          .font(.custom("Lato-Regular", size: 16))
          .foregroundStyle(Color.neutrals600)
        Spacer()
      }
      .frame(width: 200)
      .padding(.trailing, 8)
    
      VStack {
        Button {
          print("#BB \(voiceType) button clicked")
          voiceToRxViewModel.startRecording(conversationType: conversationType)
          FloatingVoiceToRxViewController.shared.showFloatingButton(viewModel: voiceToRxViewModel, liveActivityDelegate: viewModel.liveActivityDelegate)
          viewModel.v2rxEnabled = false
          Task {
            guard let v2RxSessionId = voiceToRxViewModel.sessionID else { return }
            let v2rxAudioFileString = await viewModel.fetchVoiceConversations(using: v2RxSessionId)
            let _ = await DatabaseConfig.shared.createMessage(sessionId: session, messageId: (messages.last?.msgId ?? 0) + 1 , role: .Bot, imageUrls: nil, v2RxAudioSessionId: v2RxSessionId, v2RxaudioFileString: v2rxAudioFileString)
          }
        } label: {
          Text("Start Now")
            .foregroundStyle(Color.white)
            .padding(.init(top: 7, leading: 14, bottom: 7, trailing: 14))
            .background(Color.primaryprimary)
            .cornerRadius(40)
        }
        Spacer()
      }
    }
  }
}
