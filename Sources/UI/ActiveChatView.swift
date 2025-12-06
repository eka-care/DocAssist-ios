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
import TipKit
import AVFAudio

@MainActor
public struct ActiveChatView: View {
  private let session: String
  @Environment(\.modelContext) var modelContext
  @Query private var messages: [ChatMessageModel] = []
  @State var viewModel: ChatViewModel
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
  let recordsRepo: RecordsRepo = RecordsRepo.shared
  let patientNameConstant = "General Chat"
  @State private var showFeedback = false
  @State private var feedbackText: String = ""
  @State var fetchedOid: String?
  private let userDocId: String
  private let userBId: String
  private let authToken: String
  private let authRefreshToken: String
  @State var voiceToRxTip = VoiceToRxTip()
  private let bottomScrollIdentifier = "bottomID"
  @State private var animatedText: String = ""
  @State private var lastAnimatedText: String = ""
  
  public init(session: String, viewModel: ChatViewModel, backgroundColor: Color?, patientName: String, calledFromPatientContext: Bool, title: String? = "New Chat", userDocId: String, userBId: String, authToken: String, authRefreshToken: String) {
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
    V2RxInitConfigurations.shared.delegate = SetUIComponents.shared.v2rxLoggingDelegate
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
    AuthTokenHolder.shared.authToken = authToken
    AuthTokenHolder.shared.refreshToken = authRefreshToken
    AuthTokenHolder.shared.bid = userBId
    /// To maintain the same reference
    FloatingVoiceToRxViewController.shared.viewModel = voiceToRxViewModel
  }
  
  public var body: some View {
    ZStack {
      VStack(spacing: 0) {
        if calledFromPatientContext {
          headerView
        }
        
        ScrollViewReader { proxy in
          ScrollView {
            if messages.isEmpty {
              emptyChatView
            }
            else {
              VStack {
                ForEach(messages) { message in
                  messageBubbleView(message: message)
                    .padding(.horizontal)
                    .id(message.id)
                  
                  
                  if viewModel.streamStarted && messages.last?.id == message.id {
                    if viewModel.messageText.isEmpty {
                      LoadingView()
                    }
                    
                  //  Text(viewModel.messageText)
                    Text(animatedText)
                      .onChange(of: viewModel.messageText) { _, newValue in
                        animateText(newValue)
                      }
                  }
                }
                
                Color.clear.frame(height: 1)
                  .id(bottomScrollIdentifier)
              }
              .padding(.top, 10)
              .onChange(of: isTextFieldFocused, { _, _ in
                proxy.scrollTo(bottomScrollIdentifier, anchor: .top)
              })
              .onChange(of: messages) { oldValue , newValue in
                withAnimation {
                  proxy.scrollTo(bottomScrollIdentifier, anchor: .bottom)
                }
              }
              .onAppear {
                DispatchQueue.main.async {
                  proxy.scrollTo(bottomScrollIdentifier, anchor: .bottom)
                }
              }
            }
          }
          .scrollDismissesKeyboard(.immediately)
          .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        }
        
        chatInputView
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
      
      FeedbackView(showFeedback: showFeedback, feedbackText: feedbackText)
    }
    .alert(isPresented: viewModel.showTranscriptionFailureAlertBinding) {
      Alert(
        title: Text(viewModel.alertTitle),
        message: Text(viewModel.alertMessage),
        dismissButton: .default(Text("OK"))
      )
    }
    .onAppear {
      viewModel.switchToSession(session)
      print("#BB session \(session)")
      Task {
        fetchedOid =  try await DatabaseConfig.shared.isOidPresent(sessionId: session)
          if fetchedOid != "" {
            setupView(with: fetchedOid ?? "")
          }
        await viewModel.checkandValidateWebSocketConnection()
      }
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
  
  var emptyChatView: some View {
    VStack(alignment: .leading, spacing: 8) {
        Text("Hello \(SetUIComponents.shared.docName ?? ""), how can I help you today?")
          .font(Font.custom("Lato-Regular", size: 16))
          .foregroundStyle(Color.neutrals600)
          .padding(.bottom, 4)
          .padding(.top, 20)
          .padding(.leading, 16)
      Group {
        if SetUIComponents.shared.isPatientApp == nil {
          SuggestionsComponentView(
            suggestionText: (patientName == patientNameConstant) ?
            (SetUIComponents.shared.generalChatDefaultSuggestion ?? []) :
              (SetUIComponents.shared.patientChatDefaultSuggestion ?? []),
            viewModel: viewModel
          )
        } else {
          SuggestionsComponentView(
            suggestionText: SetUIComponents.shared.patientChatDefaultSuggestion ?? ["Hello can i help you"],
            viewModel: viewModel
          )
        }
      }
      .padding(.leading, 16)
      
      Spacer()
    }
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
          recordsRepo: recordsRepo,
          voiceToRxTip: $voiceToRxTip
        )
      )
    } else {
      AnyView(
        VoiceInputView(viewModel: viewModel)
      )
    }
  }
  
  private func messageBubbleView(message: ChatMessageModel) -> some View {
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
  }
  
  private func setupView(with oid: String) {
    Task {
      viewModel.updateQueryParamsIfNeeded(oid)
      viewModel.getPatientDetailsDelegate?.getPatientDetails(ptOid: oid, completion: { userMergedOids in
        MRInitializer.shared.registerCoreSdk(authToken: authToken, refreshToken: authRefreshToken, oid: oid, bid: userBId, userMergedOids: userMergedOids ?? [])
      })
    }
  }
  
  private func animateText(_ newValue: String) {

      if newValue.count <= lastAnimatedText.count {
          animatedText = newValue
          lastAnimatedText = newValue
          return
      }

      let full = newValue
      let startIndex = full.index(full.startIndex, offsetBy: lastAnimatedText.count)
      let newChunk = full[startIndex...]

      Task {
          for char in newChunk {
              try? await Task.sleep(nanoseconds: 30_000_000)   // 0.03 sec per char (smooth)
              
              animatedText.append(char)
              lastAnimatedText.append(char)
          }
      }
  }
}

extension ActiveChatView {
  func handleVoiceToRxStates() {
    guard let sessionID = voiceToRxViewModel.sessionID else { return }
    let v2rxState = V2RxDocAssistHelper.fetchV2RxState(for: sessionID)
    /// Handle mic enable status
    if voiceToRxViewModel.screenState == .listening(conversationType: .conversation) ||
        voiceToRxViewModel.screenState == .listening(conversationType: .dictation) ||
        voiceToRxViewModel.screenState == .processing {
      DispatchQueue.main.async {
        viewModel.v2rxEnabled = false
      }
    } else {
      DispatchQueue.main.async {
        viewModel.v2rxEnabled = true
      }
    }
    if v2rxState == .deleted {
      Task {
        await DatabaseConfig.shared.deleteChatMessageByVoiceToRxSessionId(v2RxAudioSessionId: sessionID)
      }
    }
  }
}

extension View {
  func customCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(CustomCornerShape(cornerRadius: radius, corners: corners))
  }
  
  func customCornerBorder(_ radius: CGFloat, corners: UIRectCorner, color: Color, lineWidth: CGFloat = 1) -> some View {
    self
      .overlay(
        CustomCornerShape(cornerRadius: radius, corners: corners)
          .stroke(Color(red: 0.83, green: 0.87, blue: 1), lineWidth: 1)
      )
      .clipShape(CustomCornerShape(cornerRadius: radius, corners: corners))
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
