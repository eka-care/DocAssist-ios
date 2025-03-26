//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import MarkdownUI
import EkaVoiceToRx
import EkaPDFMaker
import EkaUI

struct MessageTextView: View {
  let text: String?
  let role: MessageRole
  let url: [String]?
  let message: ChatMessageModel
  let viewModel: ChatViewModel
  let createdAt: Date
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  @State private var showShareSheet = false
  @State private var pdfURL: URL?
  
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
          .ifCondition(role == .Bot) { view in
            view.contextMenu {
              Button(action: {
                UIPasteboard.general.string = text
                DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "copy", "session_id": message.sessionId,"text": text])
              }) {
                HStack {
                  Text("Copy response")
                  Spacer()
                  Image(systemName: "document.on.document")
                }
              }
              
              Button(action: {
                DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "sharepdf", "session_id": message.sessionId,"text": text])
                let fileURL = PDFRenderer().renderSinglePage(
                  headerView: AnyView( DTPDFHeaderView(
                    data: DTPDFHeaderViewData.formDeepthoughtHeaderViewData(doctorName: "DR.\(SetUIComponents.shared.docName ?? "" )", clinicName: "", address: "")
                  )),
                  bodyView: AnyView(PdfBodyView(text: text))
                )
                pdfURL = fileURL
                shareText()
                
              }) {
                HStack {
                  Text("Share as PDF")
                  Spacer()
                  Image(systemName: "square.and.arrow.up")
                }
              }
              
              Button(action: {
                DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "good", "session_id": message.sessionId,"text": text])
              }) {
                HStack {
                  Text("Good response")
                  Spacer()
                  Image(systemName: "hand.thumbsup")
                }
              }
              
              Button(action: {
                DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "bad", "session_id": message.sessionId,"text": text])
              }) {
                HStack {
                  Text("Bad response")
                  Spacer()
                  Image(systemName: "hand.thumbsdown")
                }
              }
            }
          }
      }
      
      if let v2RxAudioSessionId = message.v2RxAudioSessionId {
        V2RxChatView(
          createdAt: createdAt,
          viewModel: viewModel,
          v2rxSessionId: v2RxAudioSessionId,
          v2rxViewModel: v2rxViewModel
        )
      }
    }
  }
  
  private var backgroundColor: Color {
    role == .user ? (SetUIComponents.shared.userBackGroundColor ?? .white) : (SetUIComponents.shared.botBackGroundColor ?? .clear)
  }
  
  private var foregroundColor: Color {
    role == .user ? (SetUIComponents.shared.usertextColor ?? Color(red: 0.1, green: 0.1, blue: 0.1)) : (.neutrals800)
  }
  
  func shareText() {
    guard let url = pdfURL else { return }
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
      
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
         let rootViewController = windowScene.windows.first?.rootViewController {
          rootViewController.present(activityVC, animated: true, completion: nil)
      }
  }
}

extension View {
    @ViewBuilder func ifCondition<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct PdfBodyView: View {
  
  let text: String
  
  var body: some View {
    VStack {
      Markdown(text)
    }
    .padding(.horizontal, EkaSpacing.spacingM)
    .padding(.top, EkaSpacing.spacingM)
  }
}
