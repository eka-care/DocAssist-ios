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
  var calledFromPatientContext: Bool
  @State var chats: [SessionDataModel] = []
  @State var path = NavigationPath()
  var authToken: String
  var authRefreshToken: String
  
  init(patientName: String, viewModel: ChatViewModel, backgroundColor: Color? = nil, oid: String, userDocId: String, userBId: String, calledFromPatientContext: Bool, authToken: String, authRefreshToken: String) {
    self.patientName = patientName
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.oid = oid
    self.userDocId = userDocId
    self.userBId = userBId
    self.calledFromPatientContext = calledFromPatientContext
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    
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
              print("The oid is \(oid)")
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
            .modelContext(modelContext)
          }
        }
      
    }
  }
  var list: some View {
    ScrollView() {
      VStack {
        HStack {
          Text("\(chats.filter { !$0.chatMessages.isEmpty }.count) chats found")
            .font(Font.custom("Lato-Regular", size: 14))
            .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
            .padding(.leading, 16)
          Spacer()
        }
        
        VStack {
          ForEach(chats) { chat in
            if !chat.chatMessages.isEmpty {
              ChatRow(
                title: chat.title,
                subtitle: "Chat",
                time: viewModel.getFormatedDateToDDMMYYYY(date: chat.lastUpdatedAt),
                vm: viewModel,
                sessionId: chat.sessionId,
                patientName: patientName
              )
              Divider()
            }
          }
        }
        .background(Color.white)
        .cornerRadius(12)
      }
    }
    .padding()
    .background(Color(red: 0.96, green: 0.96, blue: 0.96))
    .onAppear {
      chats = DatabaseConfig.shared.fetchChatUsing(oid: oid)
      MRInitializer.singleTon.registerUISdk()
      MRInitializer.singleTon.registerCoreSdk(authToken: authToken, refreshToken: authRefreshToken, oid: oid, bid: userBId)
      viewModel.updateQueryParamsIfNeeded(oid)
    }
    .scrollIndicators(.hidden)
  }
}

class MRInitializer {
  
  init() {}
  
  static var singleTon = MRInitializer()
  
  func registerUISdk() {
    registerFonts()
  }
  
  private func registerFonts() {
    do {
      try Fonts.registerAllFonts()
    } catch {
      debugPrint("Failed to fetch fonts")
    }
  }
  
  func registerCoreSdk(authToken: String, refreshToken: String, oid: String, bid: String) {
    registerAuthToken(authToken: authToken, refreshToken: refreshToken, oid: oid, bid: bid)
  }
  
  private func registerAuthToken(authToken: String, refreshToken: String, oid: String, bid: String) {
    CoreInitConfigurations.shared.authToken = authToken
    CoreInitConfigurations.shared.refreshToken = refreshToken
    CoreInitConfigurations.shared.filterID = oid
    CoreInitConfigurations.shared.ownerID = bid
  }
  
}
