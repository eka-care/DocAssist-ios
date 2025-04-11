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
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let recordsRepo = RecordsRepo()
  let patientNameConstant = "General Chat"
  @State private var showFeedback = false
  @State private var feedbackText: String = ""
  @State var isOidPresent: String?
  private let userDocId: String
  private let userBId: String
  private let authToken: String
  private let authRefreshToken: String
  
  init(session: String, viewModel: ChatViewModel, backgroundColor: Color?, patientName: String, calledFromPatientContext: Bool, title: String? = "New Chat", userDocId: String, userBId: String, authToken: String, authRefreshToken: String) {
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
    
    V2RxInitConfigurations.shared.modelContainer = DatabaseConfig.shared.modelContainer
    V2RxInitConfigurations.shared.ownerOID = SetUIComponents.shared.docOId
    V2RxInitConfigurations.shared.ownerUUID = SetUIComponents.shared.docUUId
    V2RxInitConfigurations.shared.ownerName = SetUIComponents.shared.docName
    if patientName != patientNameConstant {
      V2RxInitConfigurations.shared.subOwnerName = patientName
    } else {
      V2RxInitConfigurations.shared.subOwnerName = "Clinical Note"
    }
    
    /// If reference is present use that
    if let v2rxViewModel = FloatingVoiceToRxViewController.shared.viewModel {
      voiceToRxViewModel = v2rxViewModel
    } else { /// Making sure to initialise voice init configurations before voice to rx view model
      voiceToRxViewModel = VoiceToRxViewModel(
        voiceToRxInitConfig: V2RxInitConfigurations.shared,
        voiceToRxDelegate: SetUIComponents.shared.v2rxDelegate
      )
    }
    self.userDocId = userDocId
    self.userBId = userBId
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
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
      FeedbackView(showFeedback: showFeedback, feedbackText: feedbackText)
    }
    .onChange(of: voiceToRxViewModel.screenState) { oldValue , newValue in
      if (newValue == .resultDisplay(success: true) || newValue == .resultDisplay(success: false)) {
        viewModel.v2rxEnabled = true
      }
      if newValue == .deletedRecording {
        Task {
          await DatabaseConfig.shared.deleteChatMessageByVoiceToRxSessionId(v2RxAudioSessionId: voiceToRxViewModel.sessionID!)
        }
        viewModel.v2rxEnabled = true
      }
    }
    .onAppear {
      viewModel.switchToSession(session)
      print("#BB session \(session)")
      Task {
        isOidPresent =  try await DatabaseConfig.shared.isOidPreset(sessionId: session)
        print("#BB isOidPresent: \(isOidPresent)")
        setupView()
      }
      DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
      
      Task {
          let result = await viewModel.checkForVoiceToRxResult(using: voiceToRxViewModel.sessionID)
          await MainActor.run {
              viewModel.v2rxEnabled = result
          }
      }
      
      if voiceToRxViewModel.screenState == .deletedRecording {
        Task {
          await DatabaseConfig.shared.deleteChatMessageByVoiceToRxSessionId(v2RxAudioSessionId: voiceToRxViewModel.sessionID!)
        }
      }
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
                  v2rxViewModel: voiceToRxViewModel,
                  onClickOfFeedback: {
                    showFeedback = true
                    feedbackText = "Thank you for your feedback!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                      showFeedback = false
                    }
                  },
                  onClickOfCopy: {
                    showFeedback = true
                    feedbackText = "Text copied to clipboard!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                      showFeedback = false
                    }
                  },
                  messages: messages
                )
                .padding(.horizontal)
                .id(message.id)
                
                if message.role == .user && messages.last?.id == message.id {
                  if viewModel.streamStarted {
                    LoadingView()
                  }
                }
              }
              
              Color.clear.frame(height: 1).id("bottomID")
            }
            .padding(.top, 10)
          }
          .onChange(of: isTextFieldFocused, { _, _ in
            proxy.scrollTo("bottomID", anchor: .top)
          })
          .scrollDismissesKeyboard(.immediately)
          .onChange(of: messages) { oldValue , newValue in
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
  
  private func setupView() {
    Task {
      let isOidPresent =  try await DatabaseConfig.shared.isOidPreset(sessionId: viewModel.vmssid)
      viewModel.updateQueryParamsIfNeeded(isOidPresent)
      MRInitializer.shared.registerCoreSdk(authToken: authToken, refreshToken: authRefreshToken, oid: isOidPresent, bid: userBId)
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
