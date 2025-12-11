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

public struct ExistingPatientChatsView: View {
  private let patientName: String
  private let viewModel: ChatViewModel
  private let backgroundColor: Color?
  @State private var oid: String
  private let userDocId: String
  private let userBId: String
  @State private var createNewSession: String? = "createNewSession"
  @Environment(\.dismiss) var dismiss
  private let calledFromPatientContext: Bool
  private let useNavigationStack: Bool
  @Query private var chats: [SessionDataModel] = []
  
  @State private var path = NavigationPath()
  private let authToken: String
  private let authRefreshToken: String
  
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
    
    _chats = Query(
      filter: #Predicate<SessionDataModel> { eachChat in
        eachChat.oid == oid
      },
      sort: \.lastUpdatedAt,
      order: .reverse
    )
  }
  
  public var body: some View {
    Group {
      if useNavigationStack {
        NavigationStack(path: $path) {
          listContent
            .navigationTitle(patientName)
            .navigationBarTitleDisplayMode(.large)
        }
      } else {
        listContent
          .navigationTitle(patientName)
          .navigationBarTitleDisplayMode(.large)
      }
    }
  }
  
  private var listContent: some View {
    list
      .toolbarBackground(Color.white, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task {
              let newSession = await viewModel.createSession(
                subTitle: patientName,
                oid: oid,
                userDocId: userDocId,
                userBId: userBId
              )
              createNewSession = newSession
              viewModel.switchToSession(newSession)
              DispatchQueue.main.async {
                path.append("ActiveView")
              }
            }
            DocAssistEventManager.shared.trackEvent(
              event: .docAssistHistoryClicks,
              properties: ["type": "start_new_chat"]
            )
          } label: {
            Text("New chat")
              .foregroundStyle(Color.primaryprimary)
          }
        }
      }
      .navigationDestination(for: String.self) { _ in
        ActiveChatView(
          session: viewModel.vmssid,
          viewModel: viewModel,
          backgroundColor: backgroundColor,
          patientName: patientName,
          calledFromPatientContext: false,
          userDocId: userDocId,
          userBId: userBId,
          authToken: authToken,
          authRefreshToken: authRefreshToken
        )
        .modelContext(DatabaseConfig.shared.modelContext)
      }
  }
  
  private var list: some View {
    ScrollView {
      VStack {
        HStack {
          Text("\(chats.count) chats found")
            .font(Font.custom("Lato-Regular", size: 14))
            .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            .padding(.leading, 16)
          Spacer()
        }
        
        VStack {
          ForEach(chats) { chat in
            ChatRow(
              title: chat.title,
              subtitle: "Chat",
              time: viewModel.getFormatedDateToDDMMYYYY(date: chat.lastUpdatedAt),
              vm: viewModel,
              sessionId: chat.sessionId,
              patientName: patientName,
              userDocId: userDocId,
              userBId: userBId,
              authToken: authToken,
              authRefreshToken: authRefreshToken
            )
            Divider()
          }
        }
        .background(Color.white)
        .cornerRadius(12)
      }
    }
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
    .scrollIndicators(.hidden)
    .onAppear {
      DocAssistEventManager.shared.trackEvent(
        event: .docAssistHistoryPage,
        properties: ["type": "particular_pt"]
      )
    }
  }
}
