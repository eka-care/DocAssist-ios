//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import MarkdownUI

struct MessageTextView: View {
  let text: String?
  let role: MessageRole
  let url: [String]?
  let message: ChatMessageModel
  let viewModel: ChatViewModel
  
  var body: some View {
    VStack {
      if let url = url {
        HStack {
          ForEach(Array(url.enumerated()), id: \.offset) { index, urlImage in
            let completeUrl = DocAssistFileHelper.getDocumentDirectoryURL().appendingPathComponent(urlImage)
            AsyncImage(url: completeUrl) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 86, height: 86)
                        .clipped()
                        .cornerRadius(10)
                case .failure(_):
                  ProgressView()
                   
                @unknown default:
                    ProgressView()
                }
            }
          }
        }
      }
      
      if let text, text != "" {
        Markdown(text)
          .font(.body)
          .padding(8)
          .background(backgroundColor)
          .foregroundColor(foregroundColor)
          .contentTransition(.numericText())
          .customCornerRadius(12, corners: [.bottomLeft, .bottomRight, .topLeft])
      }
      
      if let sessionId = message.v2RxAudioSessionsId {
      ClinicalNotesView(viewModel: viewModel)
      }
    }
  }
  
  private var backgroundColor: Color {
    role == .user ? (SetUIComponents.shared.userBackGroundColor ?? .white) : (SetUIComponents.shared.botBackGroundColor ?? .clear)
  }
  
  private var foregroundColor: Color {
    role == .user ? (SetUIComponents.shared.usertextColor ?? Color(red: 0.1, green: 0.1, blue: 0.1)) : (.neutrals800)
  }
}
