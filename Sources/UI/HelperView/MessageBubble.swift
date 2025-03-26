//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaVoiceToRx
import EkaPDFMaker

struct MessageBubble: View {
  let message: ChatMessageModel
  let m: String?
  let url: [String]?
  let viewModel: ChatViewModel
  @State private var pdfURL: URL?
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  @State private var thumsUpClicked: Bool = false
  @State private var thumsDownClicked: Bool = false
  var onClickOfFeedback: () -> Void
  var onClickOfCopy: () -> Void
  
  var body: some View {
    VStack {
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
          createdAt: message.createdAtDate ?? .now,
          v2rxViewModel: v2rxViewModel
        )
        .alignmentGuide(.top) { d in d[.top] }
        
        if message.role == .Bot {
          Spacer()
        }
      }
      .padding(.top, 4)
    }
    
    if (message.role == .Bot && message.messageText != nil) {
      if  !viewModel.streamStarted {
        HStack (spacing: 20) {
          Button(action: {
            thumsUpClicked.toggle()
            if thumsDownClicked {
              thumsDownClicked.toggle()
            }
            onClickOfFeedback()
            DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "good", "session_id": message.sessionId,"text": m])
          }) {
            HStack {
              Image(systemName: thumsUpClicked ? "hand.thumbsup.fill" : "hand.thumbsup")
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            }
          }
          
          Button(action: {
            thumsDownClicked.toggle()
            if thumsUpClicked {
              thumsUpClicked.toggle()
            }
            onClickOfFeedback()
            DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "bad", "session_id": message.sessionId,"text": m])
          }) {
            HStack {
              Image(systemName: thumsDownClicked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            }
          }
          Button(action: {
            onClickOfCopy()
            UIPasteboard.general.string = m
            DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "copy", "session_id": message.sessionId,"text": m])
          }) {
            HStack {
              Image(systemName: "document.on.document")
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            }
          }
          
          Button(action: {
            DocAssistEventManager.shared.trackEvent(event: .chatResponseActions, properties: ["type": "sharepdf", "session_id": message.sessionId,"text": m])
            let fileURL = PDFRenderer().renderSinglePage(
              headerView: AnyView( DTPDFHeaderView(
                data: DTPDFHeaderViewData.formDeepthoughtHeaderViewData(doctorName: "DR.\(SetUIComponents.shared.docName ?? "" )", clinicName: "", address: "")
              )),
              bodyView: AnyView(PdfBodyView(text: m ?? ""))
            )
            pdfURL = fileURL
            shareText()
            
          }) {
            HStack {
              Image(systemName: "square.and.arrow.up")
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            }
          }
          Spacer()
        }
        .padding(.leading, 30)
      }
    }
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

struct FeedbackView: View {
  var showFeedback: Bool
  var feedbackText: String
  
  var body: some View {
    if showFeedback {
      VStack {
        Text(feedbackText)
          .padding()
          .background(.black)
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 50))
          .transition(.scale)
          .zIndex(1)
          .animation(.easeInOut, value: showFeedback)
          .padding(.top, 60 )
        Spacer()
      }
    }
  }
}
