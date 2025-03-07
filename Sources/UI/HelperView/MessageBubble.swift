//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaVoiceToRx

struct MessageBubble: View {
  let message: ChatMessageModel
  let m: String?
  let url: [String]?
  let viewModel: ChatViewModel
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  
  var body: some View {
    HStack(alignment: .top) {
      if message.role == .user {
        Spacer()
      }
      
      if message.role == .Bot {
        BotAvatarImage()
          .alignmentGuide(.top) { d in d[.top] }
      }
      
      MessageTextView(
        text: m,
        role: message.role,
        url: url,
        message: message,
        viewModel: viewModel,
        createdAt: message.createdAt,
        v2rxViewModel: v2rxViewModel
      )
        .alignmentGuide(.top) { d in d[.top] }
      
      if message.role == .Bot {
        Spacer()
      }
    }
    .padding(.top, 4)
  }
}
