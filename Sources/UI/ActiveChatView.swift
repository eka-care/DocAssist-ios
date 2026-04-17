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
import TipKit
import AVFAudio

@MainActor
public struct ActiveChatView: View {
  @State private var session: String
  @Environment(\.modelContext) var modelContext
  @State var viewModel: ChatViewModel
  var backgroundColor: Color?
  @FocusState private var isTextFieldFocused: Bool
  
  private var patientName: String?
  @Environment(\.dismiss) var dismiss
  private var calledFromPatientContext: Bool
  private var subTitle: String = "Ask anything.."
  @State private var hasFocusedOnce = false
  @State private var showRecordsView = false
  @State private var selectedImages: [String] = []
  @State private var selectedDocumentId: [String] = []
  var title: String?
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
  
  @State private var animatedText: String = ""
  @State private var lastAnimatedText: String = ""
  @State private var showWSLogs: Bool = false
  @State private var isCurrentSessionEmpty: Bool = true
  @State private var inputHeight: CGFloat = 0
  @State private var glowAngle: Double = 0.0
  @State private var glowOpacity: Double = 0.0
  
  public init(session: String, viewModel: ChatViewModel, backgroundColor: Color?, patientName: String, calledFromPatientContext: Bool, title: String? = "New Chat", userDocId: String, userBId: String, authToken: String, authRefreshToken: String) {
    self._session = State(initialValue: session)
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.patientName = patientName
    self.calledFromPatientContext = calledFromPatientContext
    self.title = title
    self.userDocId = userDocId
    self.userBId = userBId
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
  }
  
  public var body: some View {
    ZStack {
      VStack(spacing: 0) {
        if calledFromPatientContext {
          headerView
        }
        
        if viewModel.chatErrorState != .none {
          sessionExpiredBanner
        }
        
        SessionChatContentView(
          session: session,
          viewModel: viewModel,
          patientName: patientName,
          patientNameConstant: patientNameConstant,
          selectedImages: $selectedImages,
          selectedDocumentId: $selectedDocumentId,
          showRecordsView: $showRecordsView,
          showFeedback: $showFeedback,
          feedbackText: $feedbackText,
          recordsRepo: recordsRepo,
          voiceToRxTip: $voiceToRxTip,
          glowAngle: $glowAngle,
          glowOpacity: $glowOpacity,
          inputHeight: $inputHeight,
          isSessionEmpty: $isCurrentSessionEmpty
        )
        .id(session)
      }
      .background(Color(red: 0.96, green: 0.96, blue: 0.96))
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
    .sheet(isPresented: $showWSLogs) {
      WebSocketLogView()
    }
    .onAppear {
      viewModel.switchToSession(session)
      print("#BB session \(session)")
      Task {
        fetchedOid = try await DatabaseConfig.shared.isOidPresent(sessionId: session)
        if fetchedOid != "" {
          setupView(with: fetchedOid ?? "")
        }
        if !viewModel.isWebSocketSetupDone {
          await viewModel.checkandValidateWebSocketConnection()
        }
      }
      DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
      WebSocketLogger.shared.logInfo("willEnterForeground received — isWebSocketSetupDone: \(viewModel.isWebSocketSetupDone)")
      guard viewModel.isWebSocketSetupDone else { return }
      Task {
        await viewModel.checkandValidateWebSocketConnection()
      }
    }
    .onChange(of: viewModel.chatErrorState) { oldState, newState in
      // Only track when error first appears — not on transitions between error states
      guard oldState == .none, newState != .none else { return }
      DocAssistEventManager.shared.trackEvent(
        event: .docAssistLandingPgClick,
        properties: [
          "type": "session_recovery_banner_shown",
          "session_id": viewModel.vmssid,
          "error_state": String(describing: newState),
          "error_reason": viewModel.lastSessionRecoveryReason ?? "unknown",
          "error_message": viewModel.webSocketErrorMessage ?? ""
        ]
      )
    }
    .onDisappear {
      viewModel.inputString = ""
    }
  }
  
  private var sessionExpiredBanner: some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.circle.fill")
        .foregroundStyle(.white)
      Text(viewModel.webSocketErrorMessage ?? "Session expired.")
        .font(Font.custom("Lato-Regular", size: 14))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
      Button {
        Task {
          if viewModel.chatErrorState == .connectionError {
            let sessionId = viewModel.vmssid
            DocAssistEventManager.shared.trackEvent(
              event: .docAssistLandingPgClick,
              properties: [
                "type": "session_recovery_retry_clicked",
                "session_id": sessionId,
                "error_reason": viewModel.lastSessionRecoveryReason ?? "unknown"
              ]
            )
            if let newToken = await viewModel.refreshSession(for: sessionId) {
              await viewModel.webSocketAuthentication(sessionId: sessionId, sessionToken: newToken)
              DocAssistEventManager.shared.trackEvent(
                event: .docAssistLandingPgClick,
                properties: [
                  "type": "session_recovery_retry_success",
                  "session_id": sessionId,
                  "error_reason": viewModel.lastSessionRecoveryReason ?? "unknown"
                ]
              )
              viewModel.lastSessionRecoveryReason = nil
              viewModel.webSocketErrorMessage = nil
              viewModel.chatErrorState = .none
            } else {
              DocAssistEventManager.shared.trackEvent(
                event: .docAssistLandingPgClick,
                properties: [
                  "type": "session_recovery_retry_failed",
                  "session_id": sessionId,
                  "error_reason": viewModel.lastSessionRecoveryReason ?? "unknown"
                ]
              )
              viewModel.webSocketErrorMessage = "Session not found. Please start a new session."
              viewModel.lastSessionRecoveryReason = "refresh_failed_after_retry"
              viewModel.chatErrorState = .sessionExpired
            }
          } else {
            let oldSessionId = viewModel.vmssid
            DocAssistEventManager.shared.trackEvent(
              event: .docAssistLandingPgClick,
              properties: [
                "type": "session_recovery_start_new_clicked",
                "session_id": oldSessionId,
                "error_reason": viewModel.lastSessionRecoveryReason ?? "unknown"
              ]
            )
            viewModel.chatErrorState = .none
            viewModel.webSocketErrorMessage = nil
            let newSessionId = await viewModel.createNewSession(
              subTitle: patientName,
              userDocId: userDocId,
              userBId: userBId
            )
            if !newSessionId.isEmpty {
              DocAssistEventManager.shared.trackEvent(
                event: .docAssistLandingPgClick,
                properties: [
                  "type": "session_recovery_start_new_success",
                  "session_id": newSessionId,
                  "previous_session_id": oldSessionId
                ]
              )
              viewModel.lastSessionRecoveryReason = nil
              session = newSessionId
            }
          }
        }
      } label: {
        Text(viewModel.chatErrorState == .connectionError ? "Retry" : "Start New")
          .font(Font.custom("Lato-Bold", size: 13))
          .foregroundStyle(.white)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.white.opacity(0.25))
          .clipShape(Capsule())
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.red.opacity(0.85))
  }
  
  private var connectionStatusColor: Color {
    switch viewModel.webSocketConnectionTitle {
    case "Connected":
      return .green
    case "Connecting...":
      return Color.orange
    default:
      return .red
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
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(Color(red: 0.42, green: 0.36, blue: 0.878))
            Text("Back")
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(Color(red: 0.42, green: 0.36, blue: 0.878))
          }
        }
        
        Spacer()
        
        HStack(spacing: 12) {
          Button {
            showWSLogs = true
          } label: {
            Text("Logs")
          }
          
          Button {
            Task {
              let newSessionId = await viewModel.createNewSession(
                subTitle: patientName,
                userDocId: userDocId,
                userBId: userBId
              )
              if !newSessionId.isEmpty {
                viewModel.chatErrorState = .none
                viewModel.webSocketErrorMessage = nil
                session = newSessionId
                isCurrentSessionEmpty = true
              }
            }
          } label: {
            Image(systemName: "plus")
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(isCurrentSessionEmpty ? Color(red: 0.42, green: 0.36, blue: 0.878).opacity(0.3) : Color(red: 0.42, green: 0.36, blue: 0.878))
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .disabled(isCurrentSessionEmpty)
        }
        .contentShape(Rectangle())
      }
      .padding(.leading, 10)
      .padding(.top, 9)
      
      VStack(alignment: .leading, spacing: 4) {
        Text("New chat")
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(.black)
        
        HStack(spacing: 6) {
          Circle()
            .fill(connectionStatusColor)
            .frame(width: 8, height: 8)
          Text(viewModel.webSocketConnectionTitle)
            .font(.system(size: 14))
            .foregroundColor(Color(.systemGray))
        }
        
        Divider()
          .padding(.top, 4)
      }
      .padding(.horizontal, 16)
      .padding(.top, 3)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
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
        try? await Task.sleep(nanoseconds: 30_000_000)
        animatedText.append(char)
        lastAnimatedText.append(char)
      }
    }
  }
}

// MARK: - SessionChatContentView
/// Inner view that owns the @Query for messages filtered by session.
/// When ActiveChatView changes the session ID and uses `.id(session)`,
/// this view is re-created with a fresh @Query for the new session.
@MainActor
struct SessionChatContentView: View {
  let session: String
  let viewModel: ChatViewModel
  let patientName: String?
  let patientNameConstant: String
  @Binding var selectedImages: [String]
  @Binding var selectedDocumentId: [String]
  @Binding var showRecordsView: Bool
  @Binding var showFeedback: Bool
  @Binding var feedbackText: String
  let recordsRepo: RecordsRepo
  @Binding var voiceToRxTip: VoiceToRxTip
  @Binding var glowAngle: Double
  @Binding var glowOpacity: Double
  @Binding var inputHeight: CGFloat
  @Binding var isSessionEmpty: Bool
  
  @Query private var messages: [ChatMessageModel] = []
  @FocusState private var isTextFieldFocused: Bool
  
  init(
    session: String,
    viewModel: ChatViewModel,
    patientName: String?,
    patientNameConstant: String,
    selectedImages: Binding<[String]>,
    selectedDocumentId: Binding<[String]>,
    showRecordsView: Binding<Bool>,
    showFeedback: Binding<Bool>,
    feedbackText: Binding<String>,
    recordsRepo: RecordsRepo,
    voiceToRxTip: Binding<VoiceToRxTip>,
    glowAngle: Binding<Double>,
    glowOpacity: Binding<Double>,
    inputHeight: Binding<CGFloat>,
    isSessionEmpty: Binding<Bool>
  ) {
    self.session = session
    self.viewModel = viewModel
    self.patientName = patientName
    self.patientNameConstant = patientNameConstant
    self._selectedImages = selectedImages
    self._selectedDocumentId = selectedDocumentId
    self._showRecordsView = showRecordsView
    self._showFeedback = showFeedback
    self._feedbackText = feedbackText
    self.recordsRepo = recordsRepo
    self._voiceToRxTip = voiceToRxTip
    self._glowAngle = glowAngle
    self._glowOpacity = glowOpacity
    self._inputHeight = inputHeight
    self._isSessionEmpty = isSessionEmpty
    _messages = Query(
      filter: #Predicate<ChatMessageModel> { message in
        message.sessionId == session
      },
      sort: \.msgId,
      order: .forward
    )
  }
  
  var body: some View {
    ZStack(alignment: .bottom) {
      Color(red: 0.96, green: 0.96, blue: 0.96)
        .ignoresSafeArea()
        .onTapGesture {
          UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
      
      ScrollViewReader { proxy in
        ScrollView {
          if messages.isEmpty {
            emptyChatView
          } else {
            VStack(spacing: 10) {
              ForEach(messages) { message in
                messageBubbleView(message: message)
                  .padding(.horizontal, 16)
                  .id(message.id)
              }

              if viewModel.streamStarted {
                if viewModel.messageText.isEmpty {
                  LoadingView()
                    .padding(.horizontal, 16)
                    .id("streamingID")
                } else {
                  HStack(alignment: .top) {
                    //   BotAvatarImage()
                    StreamingTextView(text: viewModel.messageText)
                    Spacer()
                  }
                  .padding(.horizontal, 16)
                  .id("streamingID")
                }
              }
              
              Color.clear.frame(height: 1)
                .id("bottomID")
            }
            .padding(.top, 10)
            .padding(.bottom, inputHeight)
            .onChange(of: isTextFieldFocused) { _, _ in
              withAnimation {
                proxy.scrollTo("bottomID", anchor: .bottom)
              }
            }
            .onChange(of: messages.count) { _, _ in
              if let lastMessage = messages.last {
                withAnimation(.easeOut(duration: 0.3)) {
                  proxy.scrollTo(lastMessage.id, anchor: .top)
                }
              }
            }
            .onChange(of: viewModel.messageText) { _, _ in
              if viewModel.streamStarted {
                proxy.scrollTo("streamingID", anchor: .top)
              }
            }
            .onAppear {
              DispatchQueue.main.async {
                if let lastMessage = messages.last {
                  proxy.scrollTo(lastMessage.id, anchor: .top)
                }
              }
            }
          }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
          isSessionEmpty = messages.isEmpty
        }
        .onChange(of: messages.count) { _, newCount in
          isSessionEmpty = newCount == 0
        }
      }
      
      VStack(spacing: 0) {
        chatInputView
      }
      .background(
        RoundedRectangle(cornerRadius: 24)
          .stroke(
            AngularGradient(
              stops: [
                .init(color: Color(red: 0.42, green: 0.36, blue: 0.878), location: 0.0),
                .init(color: Color(red: 0.42, green: 0.36, blue: 0.878).opacity(0.6), location: 0.35),
                .init(color: Color(red: 0.42, green: 0.36, blue: 0.878), location: 0.65),
                .init(color: Color(red: 0.42, green: 0.36, blue: 0.878), location: 1.0),
              ],
              center: .center,
              angle: .degrees(glowAngle)
            ),
            lineWidth: 6
          )
          .blur(radius: 8)
          .opacity(glowOpacity)
          .padding(.horizontal, 16)
          .padding(.vertical, 6)
          .allowsHitTesting(false)
      )
      .onAppear {
        withAnimation(.easeIn(duration: 0.3)) {
          glowOpacity = 1.0
        }
        withAnimation(.linear(duration: 1.5)) {
          glowAngle = 360.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0.0
          }
        }
      }
      .disabled(viewModel.chatErrorState != .none)
      .onGeometryChange(for: CGFloat.self) { geo in
        geo.size.height
      } action: { newHeight in
        inputHeight = newHeight
      }
    }
  }
  
  private var emptyChatView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(viewModel.initialMessageText ?? "Hello \(AuthAndUserDetailsSetter.shared.docName ?? ""), how can I help you today?")
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
            viewModel: viewModel, isMultiSelect: false
          )
        } else {
          if let apiSuggestions = viewModel.initialMessageSuggestions {
            SuggestionsComponentView(
              suggestionText: apiSuggestions,
              viewModel: viewModel, isMultiSelect: false
            )
            .padding(.leading, 16)
          }
        }
      }
      .padding(.leading, 16)
      
      Spacer()
    }
  }
  
  private var chatInputView: some View {
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
}

// MARK: - View Extensions

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
