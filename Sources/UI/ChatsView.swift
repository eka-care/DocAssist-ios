//
//  ChatsView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

//struct ChatsView: View {
//  @Query(
//    filter: #Predicate<SessionDataModel> { !$0.chatMessages.isEmpty },
//    sort: \SessionDataModel.lastUpdatedAt,
//    order: .reverse
//  ) var allSessions: [SessionDataModel]
//  @ObservedObject var viewModel: ChatViewModel
//  @State private var newSessionId: String? = nil
//  @State private var isNavigatingToNewSession: Bool = false
//  @Environment(\.modelContext) var modelContext
//  @Environment(\.dismiss) var dismiss
//  @State private var selectedSessionId: String? = nil
//  @State private var isNavigating: Bool = false
//  @State private var searchText: String = ""
//  @State private var userDocId: String
//  @State private var userBId: String
//  var backgroundColor: Color?
//  var subTitle: String? = "General Chat"
//  @State private var patientName: String? = ""
//  @State private var selectedSegement: String = "Patients"
//  var patientDelegate: NavigateToPatientDirectory
//  var searchForPatient: (() -> Void)
//  
//  var thread: [SessionDataModel] {
//    allSessions.filter { session in
//      session.userBId == userBId &&
//      session.userDocId == userDocId
//    }
//  }
//  
//  var filteredSessions: [SessionDataModel] {
//    if searchText.isEmpty {
//      return thread
//    } else {
//      return thread.filter { session in
//        session.title.localizedCaseInsensitiveContains(searchText) ||
//        (session.subTitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
//        session.chatMessages.contains { chatMessage in
//          chatMessage.messageText?.localizedCaseInsensitiveContains(searchText) ?? false
//        }
//      }
//    }
//  }
//  
//  init(backgroundColor: Color? = nil,
//       subTitle: String? = "General Chat",
//       userDocId: String,
//       userBid: String,
//       ctx: ModelContext,
//       delegate: ConvertVoiceToText,
//       patientDelegate: NavigateToPatientDirectory,
//       searchForPatient: @escaping (() -> Void)
//  ) {
//    self.backgroundColor = backgroundColor
//    self.subTitle = subTitle
//    self.viewModel = ChatViewModel(context: ctx, delegate: delegate)
//    self.userDocId = userDocId
//    self.userBId = userBid
//    self.patientDelegate = patientDelegate
//    self.searchForPatient = searchForPatient
//  }
//  
//  public var body: some View {
//    if UIDevice.current.userInterfaceIdiom == .pad {
//      ZStack {
//        if let backgroundColor = SetUIComponents.shared.userAllChatBackgroundColor {
//          Image(uiImage: backgroundColor)
//            .resizable()
//            .scaledToFill()
//            .edgesIgnoringSafeArea(.all)
//        }
//        VStack {
//          headerView
//            .padding(.bottom, 15)
//          ZStack {
//            mainContentView
//            NewChatButtonView
//              .padding(.trailing, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 0)
//              .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
//          }
//          
//        }
//        .navigationBarHidden(true)
//      }
//    } else {
//      NavigationStack {
//        ZStack {
//          VStack {
//            Image(.bg)
//                .resizable()
//                .frame(height: 180)
//                .edgesIgnoringSafeArea(.all)
//              Spacer()
//              }
//          VStack {
//            headerView
//              .padding(.bottom, 15)
//            ZStack {
//              mainContentView
//              NewChatButtonView
//                .padding(.trailing, UIDevice.current.userInterfaceIdiom == .phone ? 18 : 0)
//                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 10)
//            }
//            
//          }
//          .navigationBarHidden(true)
//          .navigationDestination(for: SessionDataModel.self) { thread in
//            if isNavigating {
//              isNavigating = false
//            }
//            return destinationView(for: thread)
//          }
//        }
//      }
//    }
//  }
//  
//  // MARK: - Header View
//  
//  private var headerView: some View {
//    VStack(alignment: .leading, spacing: 4) {
//      HStack {
//        Text(SetUIComponents.shared.chatHistoryTitle ?? "Chat History")
//          .foregroundColor(.titleColor)
//          .font(.custom("Lato-Bold", size: 34))
//          .padding(.leading, 16)
//          .padding(.top, 16)
//          .padding(.bottom, 4)
//        Spacer()
//      }
//      
//      Picker("Select", selection: $selectedSegement) {
//        Text("Patients").tag("Patients")
//        Text("All Chats").tag("All Chats")
//      }
//      .pickerStyle(SegmentedPickerStyle())
//      .padding(.horizontal, 16)
//      
//      SearchBar(text: $searchText)
//    }
//  }
//  
//  private var mainContentView: some View {
//    Group {
//      if thread.isEmpty {
//        emptyStateView
//      } else {
//        if selectedSegement == "Patients" {
//          threadListView(allChats: false)
//        } else {
//          threadListView(allChats: true)
//        }
//      }
//    }
//  }
//  
//  // MARK: - Empty State View
//  private var emptyStateView: some View {
//    VStack {
//      Divider()
//      HStack {
//        Text("Start a new chat with Doc Assist to-")
//          .fontWeight(.bold)
//          .font(.custom("Lato-Bold", size: 18))
//          .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
//          .padding(.leading, 20)
//          .padding(.top, 16)
//        Spacer()
//      }
//      HStack {
//        VStack(alignment: .leading, spacing: 12) {
//          Text("💊 Confirm drug interactions")
//          Text("🥬 Generate diet charts")
//          Text("🏋️‍♀️ Get lifestyle advice for a patient")
//          Text("📃 Generate medical certificate templates")
//          Text("and much more..")
//        }
//        .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
//        .padding(.leading, 20)
//        .padding(.top, 10)
//        .font(.custom("Lato-Regular", size: 15))
//        Spacer()
//      }
//      Spacer()
//    }
//    
//  }
//
//  private func threadListView(allChats: Bool) -> some View {
//      let filteredThreads: [SessionDataModel] = {
//          if allChats {
//              return filteredSessions
//          } else {
//              return filteredSessions.filter { $0.subTitle != "General Chat" }
//          }
//      }()
//      
//      return VStack {
//          Divider()
//          ScrollView {
//              VStack {
//                  ForEach(filteredThreads, id: \.sessionId) { thread in
//                      Button(action: {
//                          selectedSessionId = thread.sessionId
//                          isNavigating = true
//                      }) {
//                          threadItemView(for: thread, allChats: allChats)
//                      }
//                      .buttonStyle(PlainButtonStyle())
//                  }
//              }
//              .padding(.horizontal)
//          }
//          .contentMargins(.top, 0, for: .scrollContent)
//      }
//  }
//  
//  private func threadItemView(for thread: SessionDataModel, allChats: Bool) -> some View {
//    return Button(action: {
//      if selectedSessionId != thread.sessionId {
//        newSessionId = nil
//      }
//      viewModel.switchToSession(thread.sessionId)
//      selectedSessionId = thread.sessionId
//      do {
//        let patient = try DatabaseConfig.shared.fetchPatientName(fromSessionId: thread.sessionId, context: DatabaseConfig.shared.modelContext)
//        patientName = patient
//      } catch {
//        print("No patient name found")
//      }
//    }) {
//      MessageSubView(
//        thread.title,
//        viewModel.getFormatedDateToDDMMYYYY(date: thread.lastUpdatedAt),
//        thread.subTitle,
//        foregroundColor: (newSessionId == thread.sessionId) ||
//        (selectedSessionId == thread.sessionId && newSessionId == nil) ? true : false,
//        allChats
//      )
//      .background(Color.clear)
//      .background(
//        UIDevice.current.userInterfaceIdiom == .pad ?
//        RoundedRectangle(cornerRadius: 10)
//          .fill(
//            (newSessionId == thread.sessionId) ||
//            (selectedSessionId == thread.sessionId && newSessionId == nil) ? Color.primaryprimary : Color.clear)
//        : nil
//      )
//      .foregroundColor(
//        (newSessionId == thread.sessionId) ||
//        (selectedSessionId == thread.sessionId && newSessionId == nil) ? Color.blue : Color.primary
//      )
//      .contextMenu {
//        Button(role: .destructive) {
//          DatabaseConfig.shared.deleteSession(sessionId: thread.sessionId)
//        } label: {
//          Label("Delete", systemImage: "trash")
//        }
//      }
//    }
//    .buttonStyle(PlainButtonStyle())
//  }
//  
//  private func destinationView(for thread: SessionDataModel) -> some View {
//
//          return AnyView(
//              ActiveChatView(
//                  session: thread.sessionId,
//                  viewModel: viewModel,
//                  backgroundColor: backgroundColor,
//                  patientName: "General Chat",
//                  calledFromPatientContext: false
//              )
//              .modelContext(modelContext)
//          )
//
//  }
//  
//  private var NewChatButtonView: some View {
//    VStack {
//      Spacer()
//      HStack() {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//          Spacer()
//        }
//        Button(action: {
//          if allSessions.isEmpty {
//            DatabaseConfig.shared.deleteAllValues()
//          }
//          patientDelegate.navigateToPatientDirectory()
//          searchForPatient()
//        }) {
//          Image(.newChatButton)
//          if let newChatButtonText = SetUIComponents.shared.newChatButtonText {
//            Text(newChatButtonText)
//              .foregroundColor(Color.primaryprimary)
//              .font(.custom("Lato-Regular", size: 16))
//          }
//        }
//        .padding(.top, 14)
//        .padding(.bottom, 14)
//        .padding(.leading, 28)
//        .padding(.trailing, 28)
//        .background(Color.white)
//        .cornerRadius(10)
//        .overlay {
//          RoundedRectangle(cornerRadius: 10)
//            .stroke(Color.primaryprimary)
//        }
//        .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 8)
//      }
//      .padding(.bottom, 20)
//    }
//  }
//  
//  func MessageSubView(_ title: String, _ date: String, _ subTitle: String?, foregroundColor: Bool, _ allChat: Bool) -> some View {
//    
//    VStack {
//      HStack {
//        nameInitialsView(initials: getInitials(name: subTitle ?? "GeneralChat") ?? "GC")
//        VStack (spacing: 6) {
//          HStack {
//            Text(allChat ? title : subTitle ?? "General Chat")
//              .font(.custom("Lato-Regular", size: 16))
//              .foregroundColor(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .primary) : .primary)
//              .lineLimit(2)
//            Spacer()
//            Text(date)
//              .font(.caption)
//              .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
//            Image(systemName: "chevron.right")
//              .resizable()
//              .scaledToFit()
//              .frame(width: 6)
//              .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
//          }
//          HStack {
//            Text(allChat ? subTitle ?? "General Chat" : title)
//              .font(.custom("Lato-Regular", size: 14))
//              .fontWeight(.regular)
//              .foregroundStyle(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .gray) : Color.gray)
//              .lineLimit(1)
//            Spacer()
//          }
//          Divider()
//        }
//      }
//    }
//    .padding(UIDevice.current.userInterfaceIdiom == .pad ? 3 : 0)
//  }
//}
//

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

