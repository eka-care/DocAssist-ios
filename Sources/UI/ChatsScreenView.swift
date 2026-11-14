//
//  ChatListView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 02/02/25.
//

import SwiftUI
import SwiftData
import EkaVoiceToRx

enum ChatSegment: String, CaseIterable {
    case patients = "Patients"
    case allChats = "All Chats"
}

struct ChatsScreenView: View {
  @Query private var sessions: [ChatSession]
  
  var viewModel: ChatViewModel
  @State private var newSessionId: String? = nil
  @Environment(\.dismiss) var dismiss
  @State private var selectedSessionId: String? = nil
  @State private var searchText: String = ""
  @State private var userDocId: String
  @State private var userBId: String
  var backgroundColor: Color?
  var subTitle: String? = "General Chat"
  @State private var patientName: String? = ""
  @State private var selectedSegment: ChatSegment = .allChats
  @State private var selectedPatient: String?
  @Binding var selectedScreen: SelectedScreen?
  @State var selectedPatientThread: ChatSession?
  /// Chats whose replies match `searchText`; looked up when the search changes.
  @State private var replyMatches: Set<String> = []
  @State var newViewChat: Bool = false
  
  var patientDelegate: NavigateToPatientDirectory?
  var searchForPatient: (() -> Void)?
  var authToken: String
  var authRefreshToken: String
  var liveActivityDelegate: LiveActivityDelegate?
  var delegate: ConvertVoiceToText?
  var suggestionsDelegate: GetMoreSuggestions?
  var getPatientDetailsDelegate: GetPatientDetails?
  
  var filteredSessions: [ChatSession] {
    guard !searchText.isEmpty else { return sessions }
    return sessions.filter { session in
      session.title.localizedCaseInsensitiveContains(searchText) ||
      (session.patientName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
      replyMatches.contains(session.id)
    }
  }
  
  init(backgroundColor: Color? = nil,
       subTitle: String? = "General Chat",
       userDocId: String,
       userBid: String,
       delegate: ConvertVoiceToText?,
       patientDelegate: NavigateToPatientDirectory?,
       searchForPatient: (() -> Void)?,
       authToken: String,
       authRefreshToken: String,
       selectedScreen: Binding<SelectedScreen?>,
       deepThoughtNavigationDelegate: DeepThoughtsViewDelegate?,
       liveActivityDelegate: LiveActivityDelegate? = nil,
       patientName: String? = nil,
       suggestionsDelegate: GetMoreSuggestions? = nil,
       getPatientDetailsDelegate: GetPatientDetails? = nil
  ) {
    self.backgroundColor = backgroundColor
    self.subTitle = subTitle
    _sessions = Query(ChatSession.visible(doctorOid: userDocId, businessId: userBid))
    self.viewModel = ChatViewModel(
      delegate: delegate,
      deepThoughtNavigationDelegate: deepThoughtNavigationDelegate,
      liveActivityDelegate: liveActivityDelegate,
      userBid: userBid,
      userDocId: userDocId,
      patientName: patientName ?? "General Chat",
      suggestionsDelegate: suggestionsDelegate,
      getPatientDetailsDelegate: getPatientDetailsDelegate
    )
    self.userDocId = userDocId
    self.userBId = userBid
    self.patientDelegate = patientDelegate
    self.searchForPatient = searchForPatient
    self.authToken = authToken
    self.authRefreshToken = authRefreshToken
    _selectedScreen = selectedScreen
    self.liveActivityDelegate = liveActivityDelegate
    self.patientName = patientName
  }
  
  var body: some View {
    
    switch currentDevice {
    case .pad, .mac:
      chatView
      
    default:
      NavigationStack {
        chatView
          .navigationDestination(item: $selectedPatientThread) { _ in
            ActiveChatView(
              session: selectedPatientThread?.id ?? "",
              viewModel: viewModel,
              backgroundColor: .white,
              patientName: selectedPatientThread?.patientName ?? "General Chat",
              calledFromPatientContext: false,
              title: selectedPatientThread?.title,
              userDocId: userDocId,
              userBId: userBId,
              authToken: authToken,
              authRefreshToken: authRefreshToken
            )
            .modelContainer(ChatStore.container)
          }
          .navigationDestination(item: $newSessionId) { sessionId in
            ActiveChatView(
              session: sessionId,
              viewModel: viewModel,
              backgroundColor: .white,
              patientName: "General Chat",
              calledFromPatientContext: false,
              userDocId: userDocId,
              userBId: userBId,
              authToken: authToken,
              authRefreshToken: authRefreshToken
            )
            .modelContainer(ChatStore.container)
          }
      }
    }
  }
  
  private var chatView: some View {
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
          VStack {
            mainContentView
            Spacer()
          }
          NewChatButtonView
            .padding(.trailing,18)
            .padding(.leading, 10)
        }
      }
    }
    .scrollDismissesKeyboard(.immediately)
    .navigationBarHidden(true)
    .onAppear {
      DocAssistEventManager.shared.trackEvent(event: .docAssistHistoryPage, properties: ["type": "overall"])
    }
    .task {
      await ChatSync.syncSessions(doctorOid: userDocId, businessId: userBId)
    }
    .task(id: searchText) {
      replyMatches = searchText.isEmpty ? [] : await ChatStore.shared.sessionIds(withReplyContaining: searchText)
    }
  }
  
  private var headerView: some View {
    VStack(alignment: .leading, spacing: 4) {
      
 //     if SetUIComponents.shared.isPatientApp ?? false {
      if #available(iOS 26.0, *) {
        Button(action: {
          dismiss()
        }) {
          Image(systemName: "chevron.left")
            .renderingMode(.template)
            .foregroundColor(Color(.blackNeutrals))
            .font(.system(size: 24, weight: .regular))
            .padding(12)
        }
        .glassEffect(.clear.interactive(), in: .circle)
        .padding(.leading, 10)
        .padding(.top, 4)
      } else {
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
      }
    //  }
      
      HStack {
        Text(SetUIComponents.shared.chatHistoryTitle ?? "Chat History")
          .foregroundColor(.titleColor)
          .font(.custom("Lato-Bold", size: 34))
          .padding(.leading, 16)
          .padding(.top, 16)
          .padding(.bottom, 4)
        Spacer()
      }
      
      if let patientDelegate {
        Picker("Select", selection: $selectedSegment) {
          ForEach(ChatSegment.allCases, id: \.self) { segment in
            Text(segment.rawValue).tag(segment)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .onChange(of: selectedSegment) { _ , newValue in
          let properties: [String: String] = [
            "type": newValue == .allChats ? "all_chats" : "patients"
          ]
          DocAssistEventManager.shared.trackEvent(event: .docAssistHistoryTopNav, properties: properties)
        }
      }
      SearchBar(text: $searchText)
    }
  }
  
  var mainContentView: some View {
    Group {
      if sessions.isEmpty {
        EmptyStateView()
      } else {
        if selectedSegment == .patients {
          patientThreadListView()
        } else {
          threadListView(allChats: true)
        }
      }
    }
  }
  
  func patientThreadListView() -> some View {
    let groupedThreads = Dictionary(grouping: filteredSessions.filter(\.isPatientChat)) { session in
      session.patientOid ?? ""
    }
    let sortedKeys = groupedThreads.keys.sorted { key1, key2 in
        guard let sessions1 = groupedThreads[key1],
              let sessions2 = groupedThreads[key2],
              let latestSession1 = sessions1.max(by: { $0.updatedAt < $1.updatedAt }),
              let latestSession2 = sessions2.max(by: { $0.updatedAt < $1.updatedAt }) else {
            return false
        }
        return latestSession1.updatedAt > latestSession2.updatedAt
    }
    
    return VStack {
      Divider()
      ScrollView {
        LazyVStack {
          ForEach(sortedKeys, id: \.self) { key in
            if let sessions = groupedThreads[key],
               let firstSession = sessions.max(by: { $0.updatedAt < $1.updatedAt }) {
              Button {
                selectedScreen = .selectedPatient(
                  viewModel,
                  firstSession.patientOid ?? "",
                  firstSession.businessId,
                  firstSession.doctorOid,
                  firstSession.patientName ?? ""
                )
                DocAssistEventManager.shared.trackEvent(
                  event: .docAssistHistoryClicks,
                  properties: ["type": "start_new_chat"]
                )
              } label: {
                GroupPatientView(
                  subTitle: firstSession.patientName ?? "",
                  count: " \(String(sessions.count)) chats",
                  viewModel: viewModel,
                  oid: firstSession.patientOid ?? "",
                  bid: firstSession.businessId,
                  docId: firstSession.doctorOid,
                  date: viewModel.getFormatedDateToDDMMYYYY(date: firstSession.updatedAt),
                  authToken: authToken,
                  authRefreshToken: authRefreshToken,
                  liveActivityDelegate: liveActivityDelegate
                )
              }
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
    var oid: String
    var bid: String
    var docId: String
    var date: String
    var authToken: String
    var authRefreshToken: String
    var liveActivityDelegate: LiveActivityDelegate?
    
    var body: some View {
      switch currentDevice {
      case .phone:
        messageSubViewIPhone
        
      default:
          messageSubView
        
      }
    }
    
    private var messageSubViewIPhone: some View {
      NavigationLink {
        ExistingPatientChatsView(patientName: subTitle, viewModel: viewModel, oid: oid, userDocId: docId, userBId: bid, calledFromPatientContext: false, authToken: authToken ,authRefreshToken: authRefreshToken, liveActivityDelegate: liveActivityDelegate)
          .modelContainer(ChatStore.container)
      } label: {
        messageSubView
      }
    }
     
    private var messageSubView: some View {
      MessageSubViewComponent(
        title: subTitle,
        date: date,
        subTitle: count,
        foregroundColor: false,
        allChat: false
      )
      .padding(.top, 2)
      .padding(.leading, 8)
      .padding(.trailing, 8)
    }
  }
  
  
  func threadListView(allChats: Bool) -> some View {
    VStack {
      Divider()
      ScrollView {
        LazyVStack {
          ForEach(filteredSessions) { thread in
            Button {
              handleThreadSelection(thread)
            } label: {
              threadItemView(for: thread, allChats: allChats)
            }
          }
        }
        .padding(.horizontal)
      }
    }
  }
  
  func handleThreadSelection(_ thread: ChatSession) {
    selectedSessionId = thread.id
    viewModel.switchToSession(thread.id)
    selectedPatientThread = thread
    selectedScreen = .allPatient(thread, viewModel, userDocId, userBId)
  }
  
  private func threadItemView(for thread: ChatSession, allChats: Bool) -> some View {
    MessageSubViewComponent(
      title: thread.title,
      date: viewModel.getFormatedDateToDDMMYYYY(date: thread.updatedAt),
      subTitle: thread.patientName,
      foregroundColor: (newSessionId == thread.id) ||
      (selectedSessionId == thread.id && newSessionId == nil) ? true : false,
      allChat: allChats
    )
    .background(Color.clear)
    .background(
      UIDevice.current.userInterfaceIdiom == .phone ? nil :
        RoundedRectangle(cornerRadius: 10)
        .fill(
          (newSessionId == thread.id) ||
          (selectedSessionId == thread.id && newSessionId == nil) ? Color.primaryprimary : Color.clear)
    )
    .foregroundColor(
      (newSessionId == thread.id) ||
      (selectedSessionId == thread.id && newSessionId == nil) ? Color.blue : Color.primary
    )
    .contextMenu {
      Button(role: .destructive) {
        Task { await ChatStore.shared.deleteSession(id: thread.id) }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
  
  var NewChatButtonView: some View {
    VStack {
      Spacer()
      HStack() {
        Spacer()
        Button(action: {
          newViewChat = true
          if let patientDelegate {
                  patientDelegate.navigateToPatientDirectory()
                } else {
                  Task {
                    let sessionId = await viewModel.createSession(
                      subTitle: "",
                      userDocId: userDocId,
                      userBId: userBId
                    )
                    await MainActor.run {
                      self.newSessionId = sessionId
                    }
                  }
                }
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
}

var currentDevice: UIUserInterfaceIdiom {
  UIDevice.current.userInterfaceIdiom
}

func getInitials(name: String?) -> String? {
    guard let name = name, name != "General Chat" else {
        return "GeneralChat"
    }
    let words = name.uppercased().components(separatedBy: " ")
    let initials = words.prefix(2).map { $0.prefix(1) }.joined()
    return initials
}

func nameInitialsView(initials: String) -> some View {
  ZStack {
    LinearGradient(
      colors: [
        Color(red: 233/255, green: 237/255, blue: 254/255, opacity: 1.0),
        Color(red: 248/255, green: 239/255, blue: 251/255, opacity: 1.0)
      ],
      startPoint: .leading,
      endPoint: .trailing
    )
    .frame(width: 38, height: 38)
    Group {
      if initials == "GeneralChat" {
        Image(.chatMsgs)
      } else {
        Text(initials)
      }
    }
    .foregroundStyle(LinearGradient(
      colors: [
        Color(red: 32/255, green: 92/255, blue: 255/255, opacity: 1.0),
        Color(red: 174/255, green: 113/255, blue: 210/255, opacity: 1.0)
      ],
      startPoint: .leading,
      endPoint: .trailing
    ))
    .font(.custom("Lato-Bold", size: 16))
    .fontWeight(.bold)
  }
  .clipShape(Circle())
}
