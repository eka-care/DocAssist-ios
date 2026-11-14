//
//  ExistingPatientChatsView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 23/01/25.
//

import SwiftUI
import SwiftData
import EkaMedicalRecordsCore
import EkaMedicalRecordsUI
import EkaVoiceToRx

/// Every chat about one patient, newest first, with a button to start another.
public struct ExistingPatientChatsView: View {
  private let patientName: String
  private let viewModel: ChatViewModel
  private let backgroundColor: Color?
  @State private var oid: String
  private let userDocId: String
  private let userBId: String
  @Environment(\.dismiss) var dismiss
  private let calledFromPatientContext: Bool
  private let useNavigationStack: Bool
  
  @Query private var chats: [ChatSession]
  
  /// Opens the chat just created with "New chat".
  @State private var showNewChat = false
  private let authToken: String
  private let authRefreshToken: String
  var liveActivityDelegate: LiveActivityDelegate?
  
  public init(
    patientName: String,
    viewModel: ChatViewModel,
    backgroundColor: Color? = nil,
    oid: String,
    userDocId: String,
    userBId: String,
    calledFromPatientContext: Bool,
    authToken: String,
    authRefreshToken: String,
    useNavigationStack: Bool = true,
    liveActivityDelegate: LiveActivityDelegate? = nil
  ) {
    self.patientName = patientName
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.oid = oid
    self.userDocId = userDocId
    self.userBId = userBId
    self.calledFromPatientContext = calledFromPatientContext
    self.useNavigationStack = useNavigationStack
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    self.liveActivityDelegate = liveActivityDelegate
    
    _chats = Query(ChatSession.visible(patientOid: oid, doctorOid: userDocId, businessId: userBId))
  }
  
  public var body: some View {
    if useNavigationStack {
      NavigationStack {
        listContent
      }
    } else {
      listContent
    }
  }
  
  private var listContent: some View {
    List {
      ForEach(ChatListDate.sections(for: chats)) { section in
        Section(section.title) {
          ForEach(section.sessions) { chat in
            NavigationLink {
              activeChat(sessionId: chat.id, title: chat.title)
            } label: {
              ChatListRow(
                icon: "bubble.left.and.text.bubble.right",
                title: chat.title,
                details: ChatListDate.detail(for: chat.updatedAt),
                showsChevron: false
              )
            }
          }
        }
      }
      
      if chats.isEmpty {
        Section {
          VStack(spacing: 6) {
            Image(systemName: "bubble.left.and.text.bubble.right")
              .font(.largeTitle)
              .foregroundStyle(Color(.secondaryLabel))
            Text("No chats found")
              .font(.custom("Lato-Bold", size: 18))
              .foregroundStyle(Color(.secondaryLabel))
            Text("Chats about \(patientName) will be available here")
              .font(.custom("Lato-Medium", size: 12))
              .foregroundStyle(Color(.secondaryLabel))
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .padding()
        }
      }
    }
    .listStyle(.insetGrouped)
    .listSectionSpacing(.compact)
    .scrollIndicators(.hidden)
    .navigationTitle(patientName)
    .navigationBarTitleDisplayMode(.large)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: startNewChat) {
          Image(systemName: "plus")
        }
        .accessibilityLabel("New chat")
      }
    }
    .newChatButton(action: startNewChat)
    .navigationDestination(isPresented: $showNewChat) {
      activeChat(sessionId: viewModel.vmssid, title: nil)
    }
    .onAppear {
      DocAssistEventManager.shared.trackEvent(
        event: .docAssistHistoryPage,
        properties: ["type": "particular_pt"]
      )
    }
  }
  
  private func activeChat(sessionId: String, title: String?) -> some View {
    ActiveChatView(
      session: sessionId,
      viewModel: viewModel,
      backgroundColor: backgroundColor,
      patientName: patientName,
      calledFromPatientContext: false,
      title: title ?? "New Chat",
      userDocId: userDocId,
      userBId: userBId,
      authToken: authToken,
      authRefreshToken: authRefreshToken
    )
    .modelContainer(ChatStore.container)
  }
  
  private func startNewChat() {
    DocAssistEventManager.shared.trackEvent(
      event: .docAssistHistoryClicks,
      properties: ["type": "start_new_chat"]
    )
    Task {
      let newSession = await viewModel.createSession(
        subTitle: patientName,
        oid: oid,
        userDocId: userDocId,
        userBId: userBId
      )
      viewModel.switchToSession(newSession)
      await MainActor.run {
        showNewChat = true
      }
    }
  }
}
