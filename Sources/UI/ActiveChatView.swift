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
  private let session: String
  @Environment(\.modelContext) var modelContext
  @Query private var messages: [ChatMessageModel] = []
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
  @State private var inputHeight: CGFloat = 0
  @State private var glowAngle: Double = 0.0
  @State private var glowOpacity: Double = 0.0
  
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
        
        ZStack(alignment: .bottom) {
          Color(red: 0.96, green: 0.96, blue: 0.96)
            .ignoresSafeArea()
          
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
                  }

                  if viewModel.streamStarted {
                    if viewModel.messageText.isEmpty {
                      LoadingView()
                        .padding(.horizontal)
                        .id("streamingID")
                    } else {
                      HStack(alignment: .top) {
                        BotAvatarImage()
                        StreamingTextView(text: viewModel.messageText)
                        Spacer()
                      }
                      .padding(.horizontal)
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
          }

          VStack(spacing: 0) {
            chatInputView
          }
          .background(
            RoundedRectangle(cornerRadius: 24)
              .stroke(
                AngularGradient(
                  stops: [
                    .init(color: Color(red: 0.42, green: 0.2, blue: 0.9),  location: 0.0),
                    .init(color: Color(red: 0.25, green: 0.5, blue: 1.0),  location: 0.35),
                    .init(color: Color(red: 0.55, green: 0.25, blue: 1.0), location: 0.65),
                    .init(color: Color(red: 0.42, green: 0.2, blue: 0.9),  location: 1.0),
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
    .onDisappear {
      viewModel.inputString = ""
      if messages.isEmpty {
        Task {
          await DatabaseConfig.shared.deleteSession(sessionId: session)
        }
      }
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
            let sessionId = UserDefaults.standard.string(forKey: "SessionId") ?? viewModel.vmssid
            if let newToken = await viewModel.refreshSession(for: sessionId) {
              await viewModel.webSocketAuthentication(sessionId: sessionId, sessionToken: newToken)
              viewModel.webSocketErrorMessage = nil
              viewModel.chatErrorState = .none
            } else {
              viewModel.webSocketErrorMessage = "Session not found. Please start a new session."
              viewModel.chatErrorState = .sessionExpired
            }
          } else {
            viewModel.chatErrorState = .none
            viewModel.webSocketErrorMessage = nil
            let _ = await viewModel.createSession(
              subTitle: patientName,
              userDocId: userDocId,
              userBId: userBId
            )
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

  var emptyChatView: some View {
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
            
            Button {
              showWSLogs = true
            } label: {
              Text("Logs")
            }
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
            Font.custom("Lato-Bold", size: 24)
          )
          .foregroundColor(Color(red: 0.35, green: 0.03, blue: 0.5))
        Text(viewModel.webSocketConnectionTitle)
          .newTextStyle(ekaFont: .calloutRegular, color: .black)
      }
      .padding(.horizontal, 16)
      .padding(.top, 3)
      .padding(.bottom, 8)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .padding(.bottom, 5)
  }
  
  var chatInputView: some View {
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
    return MessageBubble(
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
