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
  @Query private var messages: [ChatMessage]
  private var viewModel: ChatViewModel
  var backgroundColor: Color?
  @FocusState private var isTextFieldFocused: Bool
  @State private var followsLatest = true
  @State private var isNearBottom = true
  @State private var isUserScrolling = false
  private var patientName: String?
  @Environment(\.dismiss) var dismiss
  private var calledFromPatientContext: Bool
  @State private var hasFocusedOnce = false
  @State private var showRecordsView = false
  @State private var selectedImages: [String] = []
  @State private var selectedDocumentPaths: [String] = []
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
  
  public init(session: String, viewModel: ChatViewModel, backgroundColor: Color?, patientName: String, calledFromPatientContext: Bool, title: String? = "New Chat", userDocId: String, userBId: String, authToken: String, authRefreshToken: String) {
    self.session = session
    _messages = Query(ChatMessage.inSession(session))
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.patientName = patientName
    self.calledFromPatientContext = calledFromPatientContext
    self.title = title
    
    V2RxInitConfigurations.shared.modelContainer = ChatStore.container
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
    VStack(spacing: 0) {
      if calledFromPatientContext {
        headerView
      }
      
      ScrollViewReader { proxy in
        ScrollView {
          if messages.isEmpty {
            emptyChatView
          } else {
            VStack(alignment: .leading, spacing: 18) {
              ForEach(messages) { message in
                messageBubbleView(message: message)
                  .id(message.id)
                
                if message.role == .user, messages.last?.id == message.id, viewModel.streamStarted {
                  LoadingView()
                }
              }
              
              ChatBottomMarker(id: bottomScrollIdentifier)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: messages.count)
            .onChange(of: isTextFieldFocused) { _, focused in
              guard focused else { return }
              resumeFollowing(proxy, animated: true)
            }
            /// A new message from the doctor always brings the chat back to the bottom.
            .onChange(of: messages.count) { _, _ in
              if messages.last?.role == .user {
                resumeFollowing(proxy, animated: true)
              } else {
                followIfPinned(proxy, animated: true)
              }
            }
            /// The streamed answer grows inside the same row, so the count above doesn't change.
            .onChange(of: messages.last?.text) { _, _ in
              followIfPinned(proxy)
            }
            .onAppear {
              DispatchQueue.main.async {
                proxy.scrollTo(bottomScrollIdentifier, anchor: .bottom)
              }
            }
          }
        }
        /// Drag the conversation down to pull the keyboard away, like Messages.
        .scrollDismissesKeyboard(.interactively)
        .trackChatScroll(isNearBottom: $isNearBottom, isUserScrolling: $isUserScrolling)
        /// Scrolling by hand pauses following; letting go at the bottom resumes it.
        .onChange(of: isUserScrolling) { _, scrolling in
          followsLatest = scrolling ? false : isNearBottom
        }
        .onChange(of: isNearBottom) { _, nearBottom in
          if nearBottom, !isUserScrolling {
            followsLatest = true
          }
        }
        /// The composer floats over the conversation, so messages scroll under its glass.
        .safeAreaInset(edge: .bottom, spacing: 0) {
          VStack(spacing: 8) {
            if !followsLatest, !messages.isEmpty {
              JumpToLatestButton { resumeFollowing(proxy, animated: true) }
                .transition(.scale.combined(with: .opacity))
            }
            chatInputView
          }
        }
        .animation(.easeInOut(duration: 0.2), value: followsLatest)
      }
    }
    .background(Color(.systemBackground).ignoresSafeArea())
    .overlay {
      FeedbackView(showFeedback: showFeedback, feedbackText: feedbackText)
    }
    .navigationTitle(title ?? "New Chat")
    .navigationBarTitleDisplayMode(.inline)
    .alert(isPresented: viewModel.showTranscriptionFailureAlertBinding) {
      Alert(
        title: Text(viewModel.alertTitle),
        message: Text(viewModel.alertMessage),
        dismissButton: .default(Text("OK"))
      )
    }
    .onChange(of: voiceToRxViewModel.screenState) { oldValue, newValue in
      switch newValue {
      case .resultDisplay:
        // Enable v2rx regardless of success being true or false
        viewModel.v2rxEnabled = true
        
      case .deletedRecording:
        Task {
          if let audioSessionId = voiceToRxViewModel.sessionID {
            await ChatStore.shared.deleteVoiceToRxMessages(audioSessionId: audioSessionId)
          }
        }
        viewModel.v2rxEnabled = true

      default:
        break
      }
    }
    .onAppear {
      viewModel.switchToSession(session)
      print("#BB session \(session)")
      Task {
        await ChatSync.syncMessages(sessionId: session)
      }
      Task {
        fetchedOid = await ChatStore.shared.patientOid(sessionId: session)
        if let fetchedOid, !fetchedOid.isEmpty {
          setupView(with: fetchedOid)
        }
      }
      DocAssistEventManager.shared.trackEvent(event: .docAssistLandingPage, properties: nil)
      handleVoiceToRxStates()
    }
    .onDisappear {
      viewModel.inputString = ""
      Task {
        await ChatStore.shared.discardIfEmpty(id: session)
      }
    }
  }
  
  /// A fresh chat: greeting and starter questions, centred like a native empty state.
  var emptyChatView: some View {
    VStack(spacing: 28) {
      VStack(spacing: 12) {
        AvatarImage(image: SetUIComponents.shared.chatIcon, frameSize: 40, cornerRadius: nil, foregroundColor: nil)
          .frame(width: 72, height: 72)
          .chatGlass(in: Circle(), interactive: false)
        
        Text(greeting)
          .font(.title2.weight(.bold))
        Text("How can I help you today?")
          .font(.body)
          .foregroundStyle(.secondary)
      }
      .multilineTextAlignment(.center)
      
      SuggestionsComponentView(suggestionText: starterSuggestions, viewModel: viewModel)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.horizontal, 20)
    .padding(.top, 48)
    .frame(maxWidth: .infinity)
  }
  
  private var greeting: String {
    guard let name = SetUIComponents.shared.docName, !name.isEmpty else { return "Hello" }
    return "Hello, \(name)"
  }
  
  private var starterSuggestions: [String] {
    if SetUIComponents.shared.isPatientApp != nil {
      return SetUIComponents.shared.patientChatDefaultSuggestion ?? ["Hello can i help you"]
    }
    return patientName == patientNameConstant
      ? (SetUIComponents.shared.generalChatDefaultSuggestion ?? [])
      : (SetUIComponents.shared.patientChatDefaultSuggestion ?? [])
  }
  
  /// Shown when the chat is pushed without a navigation bar (patient context).
  private var headerView: some View {
    HStack(spacing: 12) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(.primary)
          .frame(width: 44, height: 44)
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .chatGlass(in: Circle())
      .accessibilityLabel("Back")
      
      VStack(alignment: .leading, spacing: 1) {
        Text(title ?? "New Chat")
          .font(.headline)
          .lineLimit(1)
        if let patientName, patientName != patientNameConstant, !patientName.isEmpty {
          Text(patientName)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 6)
  }
  
  var chatInputView : some View {
    if viewModel.messageInput {
      AnyView(
        MessageInputView(
          inputString: viewModel.inputStringBinding,
          selectedImages: $selectedImages,
          selectedDocumentPaths: $selectedDocumentPaths,
          showRecordsView: $showRecordsView,
          patientName: patientName,
          viewModel: viewModel,
          session: session,
          messages: messages,
          voiceToRxViewModel: voiceToRxViewModel,
          recordsRepo: recordsRepo,
          voiceToRxTip: $voiceToRxTip,
          isTextFieldFocused: $isTextFieldFocused
        )
      )
    } else {
      AnyView(
        VoiceInputView(viewModel: viewModel)
      )
    }
  }
  
  // MARK: - Auto-scroll

  private func followIfPinned(_ proxy: ScrollViewProxy, animated: Bool = false) {
    guard followsLatest else { return }
    scrollToBottom(proxy, animated: animated)
  }

  private func resumeFollowing(_ proxy: ScrollViewProxy, animated: Bool = false) {
    followsLatest = true
    scrollToBottom(proxy, animated: animated)
  }

  private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
    if animated {
      withAnimation { proxy.scrollTo(bottomScrollIdentifier, anchor: .bottom) }
    } else {
      proxy.scrollTo(bottomScrollIdentifier, anchor: .bottom)
    }
  }
  
  private func messageBubbleView(message: ChatMessage) -> some View {
    MessageBubble(
      message: message,
      m: message.text,
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
}

extension ActiveChatView {
  func handleVoiceToRxStates() {
    guard let sessionID = voiceToRxViewModel.sessionID else { return }
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
  }
}
