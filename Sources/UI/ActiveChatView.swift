//
//  ActiveChatView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData
import EkaMedicalRecordsUI
import EkaMedicalRecordsCore
import EkaVoiceToRx

@MainActor
public struct ActiveChatView: View {
  private let session: String
  @Environment(\.modelContext) var modelContext
  @Query private var messages: [ChatMessageModel] = []
  private var viewModel: ChatViewModel
  var backgroundColor: Color?
  @FocusState private var isTextFieldFocused: Bool
  @State private var scrollToBottom = false
  private var patientName: String?
  @Environment(\.dismiss) var dismiss
  private var calledFromPatientContext: Bool
  private var subTitle: String = "Ask anything.."
  @State private var hasFocusedOnce = false
  @State private var showRecordsView = false
  @State private var selectedImages: [String] = []
  @State private var selectedDocumentId: [String] = []
  var title: String?
  @ObservedObject var voiceToRxViewModel = VoiceToRxViewModel()
  let recordsRepo = RecordsRepo()
  let patientNameConstant = "General Chat"
  
  init(session: String, viewModel: ChatViewModel, backgroundColor: Color?, patientName: String, calledFromPatientContext: Bool, title: String? = "New Chat") {
    self.session = session
    _messages = Query(
      filter: #Predicate<ChatMessageModel> { message in
        message.sessionId == session
      },
      sort: \.msgId,
      order: .forward
    )
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.patientName = patientName
    self.calledFromPatientContext = calledFromPatientContext
    self.title = title
    
    V2RxInitConfigurations.shared.modelContainer = modelContext.container
    V2RxInitConfigurations.shared.ownerOID = SetUIComponents.shared.docOId
    V2RxInitConfigurations.shared.ownerUUID = SetUIComponents.shared.docUUId
    V2RxInitConfigurations.shared.ownerName = SetUIComponents.shared.docName
    if patientName != patientNameConstant {
      V2RxInitConfigurations.shared.subOwnerName = patientName
    }
  }
  
  public var body: some View {
    ZStack {
      VStack {
        Image(.bg)
          .resizable()
          .frame(height: 120)
          .edgesIgnoringSafeArea(.all)
        Spacer()
      }
      VStack {
        content
      }
    }
    .onChange(of: voiceToRxViewModel.screenState) { oldValue , newValue in
      if newValue == .resultDisplay(success: true) {
        Task {
          guard let v2RxSessionId = voiceToRxViewModel.sessionID else { return }
          let v2rxAudioFileString = await viewModel.fetchVoiceConversations(using: v2RxSessionId)
          print("#BB: v2RxSessionId \(v2RxSessionId) v2rxAudioFileString: \(v2rxAudioFileString)")
          let _ = await DatabaseConfig.shared.createMessage(sessionId: session, messageId: (messages.last?.msgId ?? 0) + 1 , role: .Bot, imageUrls: nil, v2RxAudioSessionId: v2RxSessionId, v2RxaudioFileString: v2rxAudioFileString)
        }
      }
    }
    .onAppear {
      viewModel.switchToSession(session)
      DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
    }
    .onDisappear {
      viewModel.inputString = ""
      if messages.isEmpty {
        Task {
          await DatabaseConfig.shared.deleteSession(sessionId: session)
        }
      }
    }
  }
  
  private var content: some View {
    VStack {
      if calledFromPatientContext {
        headerView
      }
      newView
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
    }
  }
  
  var EmptyChatView: some View {
    VStack {
      VStack {
        Spacer()
        if let image = SetUIComponents.shared.emptyChatImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 40)
        }
        DocSuggestion(image: UIImage(resource: .chatMsgGray), title: "Ask anything from DocAssist AI", subTitle: "Medical fact checks, prescriptions and more..")
          .padding()
        DocSuggestion(image: UIImage(resource: .voiceToRxBW), title: "Create medical document", subTitle: "DocAssist AI can either listen to your live consultation or your dictation to create a medical document")
        Spacer()
      }
      chatInputView
        .padding(.bottom, 5)
    }
  }
  
  var newView: some View {
    VStack {
      if messages.isEmpty {
        EmptyChatView
      }
      else {
        ScrollViewReader { proxy in
          ScrollView {
            VStack {
              ForEach(messages) { message in
                
                MessageBubble(
                  message: message,
                  m: message.messageText,
                  url: message.imageUrls,
                  viewModel: viewModel,
                  v2rxViewModel: voiceToRxViewModel
                )
                .padding(.horizontal)
                .id(message.id)
                
                if message.role == .user && messages.last?.id == message.id {
                  LoadingView()
                  
                }
              }
              
              Color.clear.frame(height: 1).id("bottomID")
            }
            .textSelection(.enabled)
            .padding(.top, 10)
          }
          .onChange(of: isTextFieldFocused, { _, _ in
            proxy.scrollTo("bottomID", anchor: .top)
          })
          .scrollDismissesKeyboard(.immediately)
          .onChange(of: messages) { _ , _ in
            withAnimation {
              proxy.scrollTo("bottomID", anchor: .bottom)
            }
          }
          .onAppear {
            DispatchQueue.main.async {
              proxy.scrollTo("bottomID", anchor: .bottom)
            }
          }
        }
        chatInputView
          .padding(.bottom, 5)
      }
    }
    .toolbarBackground(
      LinearGradient(
        gradient: Gradient(colors: [
          Color(red: 0.93, green: 0.91, blue: 0.98),
          Color(red: 0.96, green: 0.94, blue: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
      ),
      for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .navigationTitle(title ?? "New Chat")
    .navigationBarTitleDisplayMode(.large)
  }
  
  private var headerView: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Button(action: {
          dismiss()
        }) {
          HStack(spacing: 6) {
            Image(systemName: "chevron.left")
              .font(.system(size: 21, weight: .medium))
              .foregroundColor(.blue)
            Text("Back")
              .font(Font.custom("Lato-Regular", size: 16))
              .foregroundColor(Color(red: 0.13, green: 0.37, blue: 1))
            Spacer()
          }
        }
        .contentShape(Rectangle())
        Spacer()
      }
      .padding(.leading, 10)
      .padding(.top, 9)
      
      VStack(alignment: .leading, spacing: 0) {
        Text("New chat")
          .font(
            Font.custom("Lato-Bold", size: 34)
          )
          .foregroundColor(Color(red: 0.35, green: 0.03, blue: 0.5))
        
        Text("Parrotlet Lite")
          .font(Font.custom("Lato-Regular", size: 14))
          .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 16)
      .padding(.top, 3)
      .padding(.bottom, 8)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .padding(.bottom, 5)
  }
  
  var chatInputView : some View {
    if viewModel.messageInput {
      AnyView(
        MessageInputView(
          inputString: viewModel.inputStringBinding,
          selectedImages: $selectedImages,
          selectedDocumentId: $selectedDocumentId,
          showRecordsView: $showRecordsView,
          patientName: patientName,
          viewModel: viewModel,
          session: session,
          messages: messages,
          voiceToRxViewModel: voiceToRxViewModel,
          recordsRepo: recordsRepo
        )
      )
    } else {
      AnyView(
        VoiceInputView(viewModel: viewModel)
      )
    }
  }
}

extension View {
  func customCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(CustomCornerShape(cornerRadius: radius, corners: corners))
  }
}

struct CustomCornerShape: Shape {
  var cornerRadius: CGFloat
  var corners: UIRectCorner
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
    )
    return Path(path.cgPath)
  }
}
