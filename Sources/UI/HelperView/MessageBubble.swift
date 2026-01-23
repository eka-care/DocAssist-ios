//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaVoiceToRx
import EkaPDFMaker

enum SuggestionsState {
  case generate
  case loading
  case noMore
}

struct MessageBubble: View {
  let message: ChatMessageModel
  let m: String?
  let url: [String]?
  let viewModel: ChatViewModel
  @State var suggestionViewModel = SuggestionsViewModel()
  @State private var pdfURL: URL?
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  
  @State private var thumsUpClicked: Bool = false
  @State private var thumsDownClicked: Bool = false
  @State private var copyClicked: Bool = false
  
  var onClickOfFeedback: () -> Void
  var onClickOfCopy: () -> Void
  var messages: [ChatMessageModel]
  
  // MARK: - Only show UI when bot message actually has visible text
  private var hasVisibleBotMessage: Bool {
    guard let text = m else { return false }
    return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      
      HStack(alignment: .top) {
        if message.role == .user {
          Spacer()
        }
        
        if message.role == .Bot && hasVisibleBotMessage {
          BotAvatarImage()
            .alignmentGuide(.top) { d in d[.top] }
        }
        
        if hasVisibleBotMessage {
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
        }
        
        if message.role == .Bot {
          Spacer()
        }
      }
      .padding(.top, 4)
      
      if message.role == .Bot && hasVisibleBotMessage {
        if ((message.id != messages.last?.id) ||
            (message.id == messages.last?.id && !viewModel.streamStarted)) {
          
          HStack(spacing: 8) {
            Button(action: {
              generateHapticFeedback()
              withAnimation {
                thumsUpClicked.toggle()
                if thumsDownClicked { thumsDownClicked = false }
              }
              onClickOfFeedback()
              DocAssistEventManager.shared.trackEvent(
                event: .chatResponseActions,
                properties: [
                  "type": "good",
                  "session_id": message.sessionId,
                  "text": m
                ]
              )
            }) {
              Image(systemName: thumsUpClicked ? "hand.thumbsup.fill" : "hand.thumbsup")
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                .frame(width: 34, height: 34)
            }
            

            Button(action: {
              generateHapticFeedback()
              withAnimation {
                thumsDownClicked.toggle()
                if thumsUpClicked { thumsUpClicked = false }
              }
              onClickOfFeedback()
              DocAssistEventManager.shared.trackEvent(
                event: .chatResponseActions,
                properties: [
                  "type": "bad",
                  "session_id": message.sessionId,
                  "text": m
                ]
              )
            }) {
              Image(systemName: thumsDownClicked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                .scaledToFit()
                .frame(width: 18)
                .padding(4)
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                .frame(width: 34, height: 34)
            }
            
            Button(action: {
              withAnimation { copyClicked = true }
              DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation { copyClicked = false }
              }
              generateHapticFeedback()
              onClickOfCopy()
              UIPasteboard.general.string = m
              DocAssistEventManager.shared.trackEvent(
                event: .chatResponseActions,
                properties: [
                  "type": "copy",
                  "session_id": message.sessionId,
                  "text": m
                ]
              )
            }) {
              Image(systemName: copyClicked ? "checkmark" : "document.on.document")
                .scaledToFit()
                .padding(4)
                .contentTransition(.symbolEffect(.replace))
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                .frame(width: 34, height: 34)
            }
            
            // SHARE PDF
            Button(action: {
              generateHapticFeedback()
              DocAssistEventManager.shared.trackEvent(
                event: .chatResponseActions,
                properties: [
                  "type": "sharepdf",
                  "session_id": message.sessionId,
                  "text": m
                ]
              )
              let fileURL = PDFRenderer().renderSinglePage(
                headerView: AnyView(DTPDFHeaderView(
                  data: DTPDFHeaderViewData.formDeepthoughtHeaderViewData(
                    doctorName: "DR.\(SetUIComponents.shared.docName ?? "" )",
                    clinicName: "",
                    address: ""
                  )
                )),
                bodyView: AnyView(PdfBodyView(text: m ?? ""))
              )
              pdfURL = fileURL
              shareText()
            }) {
              Image(systemName: "square.and.arrow.up")
                .fontWeight(.medium)
                .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                .frame(width: 34, height: 34)
            }
            
            Spacer()
          }
          .padding(.leading, 30)
        }
      }
    
      if message.role == .Bot {
        if let suggestions = message.suggestions {
          VStack(alignment: .leading) {
            SuggestionView(
              suggestionText: suggestions,
              viewModel: viewModel,
              isMultiSelect: message.multiselect ?? false
            )
          }
          .padding(.vertical, 16)
        }
      }
    }
  }
  
  func shareText() {
    guard let url = pdfURL else { return }
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController {
      
      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = rootVC.view
        popover.sourceRect = CGRect(
          x: rootVC.view.bounds.midX,
          y: rootVC.view.bounds.midY,
          width: 0,
          height: 0
        )
        popover.permittedArrowDirections = []
      }
      
      rootVC.present(activityVC, animated: true)
    }
  }
  
  // MARK: - Haptics
  private func generateHapticFeedback() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.prepare()
    generator.impactOccurred()
  }
}

