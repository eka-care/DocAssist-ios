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
  @State private var openTick = 0
  
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
  
  // MARK: - List

  private var chatView: some View {
    List {
      if patientDelegate != nil {
        /// Inside the list (not a top inset) so the large title and pull-to-refresh
        /// stay attached to the navigation bar; tight spacing keeps it close to the first section.
        Section {
          segmentPicker
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listSectionSpacing(4)
      }
      
      if selectedSegment == .patients {
        patientRows
      } else {
        chatSections
      }
      
      emptyState
    }
    .listStyle(.insetGrouped)
    .listSectionSpacing(.compact)
    .scrollIndicators(.hidden)
    .navigationTitle(SetUIComponents.shared.chatHistoryTitle ?? "Chats")
    .navigationBarTitleDisplayMode(.large)
    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search chats")
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
        }
        .accessibilityLabel("Back")
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: startNewChat) {
          Image(systemName: "plus")
        }
        .accessibilityLabel("New chat")
      }
    }
    .newChatButton(action: startNewChat)
    .sensoryFeedback(.selection, trigger: openTick)
    .refreshable {
      await ChatSync.syncSessions(doctorOid: userDocId, businessId: userBId)
    }
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
  
  private var segmentPicker: some View {
    Picker("Show", selection: $selectedSegment) {
      ForEach(ChatSegment.allCases, id: \.self) { segment in
        Text(segment.rawValue).tag(segment)
      }
    }
    .pickerStyle(.segmented)
    .onChange(of: selectedSegment) { _, newValue in
      DocAssistEventManager.shared.trackEvent(
        event: .docAssistHistoryTopNav,
        properties: ["type": newValue == .allChats ? "all_chats" : "patients"]
      )
    }
  }
  
  // MARK: All chats
  
  /// Today, Yesterday, then one section per day, as in EkaScribe's past sessions.
  private var chatSections: some View {
    ForEach(ChatListDate.sections(for: filteredSessions)) { section in
      Section(section.title) {
        ForEach(section.sessions) { session in
          chatRow(session)
        }
      }
    }
  }
  
  private func chatRow(_ session: ChatSession) -> some View {
    let selected = isSelected(session)
    return ChatListRow(
      icon: session.listIcon,
      title: session.title,
      details: session.listDetails,
      isSelected: selected
    )
    .onTapGesture { handleThreadSelection(session) }
    .listRowBackground(selected ? Color.primaryprimary : nil)
  }
  
  /// Highlighted on iPad, where the open chat shows beside the list.
  private func isSelected(_ session: ChatSession) -> Bool {
    guard currentDevice != .phone else { return false }
    if let newSessionId { return newSessionId == session.id }
    return selectedSessionId == session.id
  }
  
  func handleThreadSelection(_ thread: ChatSession) {
    openTick += 1
    selectedSessionId = thread.id
    viewModel.switchToSession(thread.id)
    selectedPatientThread = thread
    selectedScreen = .allPatient(thread, viewModel, userDocId, userBId)
  }
  
  // MARK: Patients
  
  private struct PatientGroup: Identifiable {
    let oid: String
    let name: String
    let count: Int
    let latest: ChatSession
    var id: String { oid }
    
    var details: String {
      "\(count == 1 ? "1 chat" : "\(count) chats") · \(ChatListDate.detail(for: latest.updatedAt))"
    }
  }
  
  /// One entry per patient, ordered by their most recent chat.
  private var patientGroups: [PatientGroup] {
    Dictionary(grouping: filteredSessions.filter(\.isPatientChat)) { $0.patientOid ?? "" }
      .compactMap { oid, chats in
        guard let latest = chats.max(by: { $0.updatedAt < $1.updatedAt }) else { return nil }
        return PatientGroup(oid: oid, name: latest.patientName ?? "", count: chats.count, latest: latest)
      }
      .sorted { $0.latest.updatedAt > $1.latest.updatedAt }
  }
  
  private var patientRows: some View {
    Section {
      ForEach(patientGroups) { group in
        patientRow(group)
      }
    }
  }
  
  @ViewBuilder
  private func patientRow(_ group: PatientGroup) -> some View {
    if currentDevice == .phone {
      NavigationLink {
        ExistingPatientChatsView(
          patientName: group.name,
          viewModel: viewModel,
          oid: group.oid,
          userDocId: group.latest.doctorOid,
          userBId: group.latest.businessId,
          calledFromPatientContext: false,
          authToken: authToken,
          authRefreshToken: authRefreshToken,
          useNavigationStack: false,
          liveActivityDelegate: liveActivityDelegate
        )
        .modelContainer(ChatStore.container)
      } label: {
        ChatListRow(icon: "person.crop.circle", title: group.name, details: group.details, showsChevron: false)
      }
      .simultaneousGesture(TapGesture().onEnded { trackPatientOpened() })
    } else {
      ChatListRow(icon: "person.crop.circle", title: group.name, details: group.details)
        .onTapGesture {
          selectedScreen = .selectedPatient(viewModel, group.oid, group.latest.businessId, group.latest.doctorOid, group.name)
          trackPatientOpened()
        }
    }
  }
  
  private func trackPatientOpened() {
    DocAssistEventManager.shared.trackEvent(event: .docAssistHistoryClicks, properties: ["type": "start_new_chat"])
  }
  
  // MARK: - Empty state
  
  /// Shown inside the list, as in EkaScribe.
  @ViewBuilder
  private var emptyState: some View {
    let isEmpty = selectedSegment == .patients ? patientGroups.isEmpty : filteredSessions.isEmpty
    if isEmpty {
      Section {
        VStack(spacing: 6) {
          Image(systemName: searchText.isEmpty ? "bubble.left.and.text.bubble.right" : "magnifyingglass")
            .font(.largeTitle)
            .foregroundStyle(Color(.secondaryLabel))
          Text(searchText.isEmpty ? "No chats found" : "No results for “\(searchText)”")
            .font(.custom("Lato-Bold", size: 18))
            .foregroundStyle(Color(.secondaryLabel))
          Text(emptyMessage)
            .font(.custom("Lato-Medium", size: 12))
            .foregroundStyle(Color(.secondaryLabel))
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
      }
    }
  }
  
  private var emptyMessage: String {
    if !searchText.isEmpty { return "Try a different patient name or keyword" }
    if selectedSegment == .patients { return "Chats you start from a patient's profile will be available here" }
    return "Your chats will be available here"
  }
  
  // MARK: - New chat
  
  /// With a patient directory, the doctor picks a patient first; otherwise a general chat opens.
  private func startNewChat() {
    newViewChat = true
    if let patientDelegate {
      patientDelegate.navigateToPatientDirectory()
      return
    }
    Task {
      let sessionId = await viewModel.createSession(subTitle: "", userDocId: userDocId, userBId: userBId)
      await MainActor.run {
        newSessionId = sessionId
      }
    }
  }
}

var currentDevice: UIUserInterfaceIdiom {
  UIDevice.current.userInterfaceIdiom
}
