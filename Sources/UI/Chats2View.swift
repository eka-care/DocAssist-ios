//
//  Chats2View.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 02/02/25.
//

import SwiftUI
import SwiftData

struct Chats2View: View {
  @Query(
    filter: #Predicate<SessionDataModel> { !$0.chatMessages.isEmpty },
    sort: \SessionDataModel.lastUpdatedAt,
    order: .reverse
  ) var allSessions: [SessionDataModel]
  @ObservedObject var viewModel: ChatViewModel
  @State private var newSessionId: String? = nil
  @State private var isNavigatingToNewSession: Bool = false
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  @State private var selectedSessionId: String? = nil
  @State private var isNavigating: Bool = false
  @State private var searchText: String = ""
  @State private var userDocId: String
  @State private var userBId: String
  var backgroundColor: Color?
  var subTitle: String? = "General Chat"
  @State private var patientName: String? = ""
  @State private var selectedSegement: String = "Patients"
  var patientDelegate: NavigateToPatientDirectory
  var searchForPatient: (() -> Void)
  var authToken: String
  var authRefreshToken: String
  
  var thread: [SessionDataModel] {
    allSessions.filter { session in
      session.userBId == userBId &&
      session.userDocId == userDocId
    }
  }
  
  var filteredSessions: [SessionDataModel] {
    if searchText.isEmpty {
      return thread
    } else {
      return thread.filter { session in
        session.title.localizedCaseInsensitiveContains(searchText) ||
        (session.subTitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
        session.chatMessages.contains { chatMessage in
          chatMessage.messageText?.localizedCaseInsensitiveContains(searchText) ?? false
        }
      }
    }
  }
  
  init(backgroundColor: Color? = nil,
       subTitle: String? = "General Chat",
       userDocId: String,
       userBid: String,
       ctx: ModelContext,
       delegate: ConvertVoiceToText,
       patientDelegate: NavigateToPatientDirectory,
       searchForPatient: @escaping (() -> Void),
       authToken: String,
       authRefreshToken: String
  ) {
    self.backgroundColor = backgroundColor
    self.subTitle = subTitle
    self.viewModel = ChatViewModel(context: ctx, delegate: delegate)
    self.userDocId = userDocId
    self.userBId = userBid
    self.patientDelegate = patientDelegate
    self.searchForPatient = searchForPatient
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
  }
  
  var body: some View {
    NavigationStack {
      ZStack {
        VStack {
          Image(.bg)
            .resizable()
            .frame(height: 180)
            .edgesIgnoringSafeArea(.all)
          Spacer()
        }
        
        VStack {
          headerView
            .padding(.bottom, 15)
          ZStack {
            mainContentView
            NewChatButtonView
              .padding(.trailing, UIDevice.current.userInterfaceIdiom == .phone ? 18 : 0)
              .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 10)
          }
        }
      }
      .navigationBarHidden(true)
    }
  }
  private var headerView: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(SetUIComponents.shared.chatHistoryTitle ?? "Chat History")
          .foregroundColor(.titleColor)
          .font(.custom("Lato-Bold", size: 34))
          .padding(.leading, 16)
          .padding(.top, 16)
          .padding(.bottom, 4)
        Spacer()
      }
      
      Picker("Select", selection: $selectedSegement) {
        Text("Patients").tag("Patients")
        Text("All Chats").tag("All Chats")
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal, 16)
      
      SearchBar(text: $searchText)
    }
  }
  
  var mainContentView: some View {
    Group {
      if thread.isEmpty {
        emptyStateView
      } else {
        if selectedSegement == "Patients" {
          patientThreadListView()
        } else {
          threadListView(allChats: true)
        }
      }
    }
  }
  
  var emptyStateView: some View {
    VStack {
      Divider()
      HStack {
        Text("Start a new chat with Doc Assist to-")
          .fontWeight(.bold)
          .font(.custom("Lato-Bold", size: 18))
          .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
          .padding(.leading, 20)
          .padding(.top, 16)
        Spacer()
      }
      HStack {
        VStack(alignment: .leading, spacing: 12) {
          Text("💊 Confirm drug interactions")
          Text("🥬 Generate diet charts")
          Text("🏋️‍♀️ Get lifestyle advice for a patient")
          Text("📃 Generate medical certificate templates")
          Text("and much more..")
        }
        .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
        .padding(.leading, 20)
        .padding(.top, 10)
        .font(.custom("Lato-Regular", size: 15))
        Spacer()
      }
      Spacer()
    }
    
  }
  
  func patientThreadListView() -> some View {
    let groupedThreads = Dictionary(grouping: filteredSessions.filter { !($0.oid?.isEmpty ?? true) }) { session in
      session.oid ?? ""
    }
    return VStack {
      Divider()
      ScrollView {
        VStack {
          ForEach(groupedThreads.keys.sorted(), id: \.self) { key in
            if let sessions = groupedThreads[key], let firstSession = sessions.first {
              
              GroupPatientView(subTitle: firstSession.subTitle ?? "", count: " \(String(sessions.count)) chats", viewModel: viewModel, ctx: modelContext,oid: firstSession.oid ?? "" , bid: firstSession.userBId, docId: firstSession.userDocId,date: viewModel.getFormatedDateToDDMMYYYY(date: firstSession.lastUpdatedAt), authToken: authToken, authRefreshToken: authRefreshToken)
            }
          }
        }
      }
    }
  }
  
  struct GroupPatientView: View {
    var subTitle: String
    var count: String
    var viewModel: ChatViewModel
    var ctx: ModelContext
    var oid: String
    var bid: String
    var docId: String
    var date: String
    var authToken: String
    var authRefreshToken: String
    
    var body: some View {
      NavigationLink {
        ExistingPatientChatsView(patientName: subTitle, viewModel: viewModel, oid: oid, userDocId: docId, userBId: bid, ctx: ctx, calledFromPatientContext: false, authToken: authToken ,authRefreshToken: authRefreshToken)
      } label: {
        MessageSubViewComponent(
          title: count,
          date: date,
          subTitle: subTitle,
          foregroundColor: true,
          allChat: false
        )
        .padding(.top, 2)
        .padding(.leading, 8)
        .padding(.trailing, 8)
      }
    }
  }
  
  
  func threadListView(allChats: Bool) -> some View {
    let filteredThreads: [SessionDataModel] = {
      if allChats {
        return filteredSessions
      } else {
        return filteredSessions.filter { $0.oid != "" }
      }
    }()
    
    return VStack {
      Divider()
      ScrollView {
        VStack {
          ForEach(filteredThreads, id: \.sessionId) { thread in
            Button(action: {
              handleThreadSelection(thread)
            }) {
              threadItemView(for: thread, allChats: allChats)
                .onAppear {
                  print("#BB oid is \(thread.oid ?? "")")
                }
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .padding(.horizontal)
      }
    }
  }
  
  func handleThreadSelection(_ thread: SessionDataModel) {
    selectedSessionId = thread.sessionId
    viewModel.switchToSession(thread.sessionId)
    
    do {
      let patient = try DatabaseConfig.shared.fetchPatientName(
        fromSessionId: thread.sessionId,
        context: DatabaseConfig.shared.modelContext
      )
      patientName = patient
    } catch {
      print("No patient name found")
    }
  }
  
  private func threadItemView(for thread: SessionDataModel, allChats: Bool) -> some View {
    MessageSubView(
      thread,
      thread.title,
      viewModel.getFormatedDateToDDMMYYYY(date: thread.lastUpdatedAt),
      thread.subTitle,
      foregroundColor: (newSessionId == thread.sessionId) ||
      (selectedSessionId == thread.sessionId && newSessionId == nil) ? true : false,
      allChats
    )
    .background(Color.clear)
    .background(
      UIDevice.current.userInterfaceIdiom == .pad ?
      RoundedRectangle(cornerRadius: 10)
        .fill(
          (newSessionId == thread.sessionId) ||
          (selectedSessionId == thread.sessionId && newSessionId == nil) ? Color.primaryprimary : Color.clear)
      : nil
    )
    .foregroundColor(
      (newSessionId == thread.sessionId) ||
      (selectedSessionId == thread.sessionId && newSessionId == nil) ? Color.blue : Color.primary
    )
    .contextMenu {
      Button(role: .destructive) {
        DatabaseConfig.shared.deleteSession(sessionId: thread.sessionId)
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
  
  var NewChatButtonView: some View {
    VStack {
      Spacer()
      HStack() {
        if UIDevice.current.userInterfaceIdiom == .phone {
          Spacer()
        }
        Button(action: {
          if allSessions.isEmpty {
            DatabaseConfig.shared.deleteAllValues()
          }
          patientDelegate.navigateToPatientDirectory()
          searchForPatient()
        }) {
          Image(.newChatButton)
          if let newChatButtonText = SetUIComponents.shared.newChatButtonText {
            Text(newChatButtonText)
              .foregroundColor(Color.primaryprimary)
              .font(.custom("Lato-Regular", size: 16))
          }
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
        .padding(.leading, 28)
        .padding(.trailing, 28)
        .background(Color.white)
        .cornerRadius(10)
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color.primaryprimary)
        }
        .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 8)
      }
      .padding(.bottom, 20)
    }
  }
  
  func MessageSubView(_ thread: SessionDataModel, _ title: String, _ date: String, _ subTitle: String?, foregroundColor: Bool, _ allChat: Bool) -> some View {
    
    NavigationLink {
      ActiveChatView(
        session: thread.sessionId,
        viewModel: viewModel,
        backgroundColor: .white,
        patientName: thread.subTitle ?? "General Chat",
        calledFromPatientContext: false,
        title: title
      )
    } label: {
      MessageSubViewComponent(
        title: title,
        date: date,
        subTitle: subTitle,
        foregroundColor: foregroundColor,
        allChat: allChat
      )
    }
  }
  
  struct MessageSubViewComponent: View {
    let title: String
    let date: String
    let subTitle: String?
    let foregroundColor: Bool
    let allChat: Bool
    
    var body: some View {
      VStack {
        HStack {
          nameInitialsView(initials: getInitials(name: subTitle ?? "GeneralChat") ?? "GC")
          VStack(spacing: 6) {
            HStack {
              Text(allChat ? title : subTitle ?? "General Chat")
                .font(.custom("Lato-Regular", size: 16))
                .foregroundColor(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .primary) : .primary)
                .lineLimit(2)
              Spacer()
              Text(date)
                .font(.caption)
                .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
              Image(systemName: "chevron.right")
                .resizable()
                .scaledToFit()
                .frame(width: 6)
                .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
            }
            HStack {
              Text(allChat ? subTitle ?? "General Chat" : title)
                .font(.custom("Lato-Regular", size: 14))
                .fontWeight(.regular)
                .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
                .lineLimit(1)
              Spacer()
            }
            Divider()
          }
        }
      }
      .padding(UIDevice.current.userInterfaceIdiom == .pad ? 3 : 0)
    }
  }
}
