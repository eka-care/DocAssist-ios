//
//  ExistingPatientChatsView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 23/01/25.
//

import SwiftUI
import SwiftData

public struct ExistingPatientChatsView: View {
  @State var patientName: String
  @State private var navigateToActiveChatView: Bool = false
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundColor: Color?
  var oid: String
  var userDocId: String
  var userBId: String
  @State var createNewSession: String?
  @Environment(\.dismiss) var dismiss
  @Environment(\.modelContext) var modelContext
  var sessions: [String]
  var ctx: ModelContext
  var calledFromPatientContext: Bool
  @State var chats: [SessionDataModel] = []
  @State var path = NavigationPath()
  
  init(patientName: String, viewModel: ChatViewModel, backgroundColor: Color? = nil, oid: String, userDocId: String, userBId: String, sessions: [String], ctx: ModelContext, calledFromPatientContext: Bool) {
    self.patientName = patientName
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.oid = oid
    self.userDocId = userDocId
    self.userBId = userBId
    self.sessions = sessions
    self.ctx = ctx
    self.calledFromPatientContext = calledFromPatientContext
  }
  
  public var body: some View {
    NavigationStack(path: $path) {
      list
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
          if calledFromPatientContext {
            ToolbarItem(placement: .navigationBarLeading) {
              Button {
                dismiss()
              } label: {
                Image(systemName: "chevron.left")
                  .font(.system(size: 21, weight: .medium))
                  .foregroundColor(Color.primaryprimary)
                Text("Back")
                  .foregroundStyle(Color.primaryprimary)
              }
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button {
              createNewSession = viewModel.createSession(subTitle: patientName, oid: oid, userDocId: userDocId, userBId: userBId)
              path.append("ActiveView")
            }
            label: {
              Text("New chat")
                .foregroundStyle(Color.primaryprimary)
            }
          }
        }
        .navigationTitle(patientName)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: String.self) { str in
          if str == "ActiveView" {
            ActiveChatView(
              session: createNewSession ?? "",
              viewModel: viewModel,
              backgroundColor: backgroundColor,
              patientName: patientName,
              calledFromPatientContext: false)
            .modelContext(ctx)
          }
        }
      
    }
  }
  var list: some View {
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
              time: "2m ago",
              vm: viewModel,
              oid: chat.oid ?? "No oid present",
              sessionId: chat.sessionId,
              patientName: patientName
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
    .onAppear {
      chats = DatabaseConfig.shared.fetchChatUsing(patientName: patientName)
    }
  }
}
