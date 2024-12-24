//
//  MainView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

struct MainView: View {
  
  @Query(sort: \SessionDataModel.lastUpdatedAt, order: .reverse) var thread: [SessionDataModel]
  @ObservedObject var viewModel: ChatViewModel
  @State private var newSessionId: String? = nil
  @State private var isNavigatingToNewSession: Bool = false
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  @State private var selectedSessionId: String? = nil
  @State private var isNavigating: Bool = false
  @State private var searchText: String = ""
  private var bgcolors: Color
  var backgroundColor: Color?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String? = "General Chat"
  @State private var patientName: String? = ""
  
  init(backgroundColor: Color? = nil, emptyMessageColor: Color? = .white, editButtonColor: Color? = .blue, subTitle: String? = "General Chat", ctx: ModelContext, delegate: ConvertVoiceToText) {
    self.backgroundColor = backgroundColor
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.viewModel = ChatViewModel(context: ctx, delegate: delegate)
    self.bgcolors = SetUIComponents.shared.emptyHistoryBgColor ?? Color.gray
  }

  public var body: some View {
    if UIDevice.current.userInterfaceIdiom == .pad {
      ZStack {
        if let backgroundColor = SetUIComponents.shared.userAllChatBackgroundColor {
          Image(uiImage: backgroundColor)
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
        }
        VStack {
          headerView
            .padding(.bottom, 20)
          ZStack {
            mainContentView
            editButtonView
              .padding(.trailing, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 0)
              .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 0)
          }
          
        }
        .navigationBarHidden(true)
      }
      .background(
        NavigationLink(
          destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel, backgroundColor: backgroundColor, patientName: subTitle ?? "General Chat", calledFromPatientContext: false)
            .modelContext(modelContext),
          isActive: $isNavigatingToNewSession
        ) {
          EmptyView()
        }
      )
    } else {
      NavigationView {
        ZStack {
          if let backgroundColor = SetUIComponents.shared.userAllChatBackgroundColor {
            Image(uiImage: backgroundColor)
              .resizable()
              .scaledToFill()
              .edgesIgnoringSafeArea(.all)
          }
          VStack {
            headerView
              .padding(.bottom, 20)
            ZStack {
              mainContentView
              editButtonView
                .padding(.trailing, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 0)
                .padding(.leading, UIDevice.current.userInterfaceIdiom == .pad ? 20 : 10)
            }
            
          }
          .navigationBarHidden(true)
        }
        .background(
          NavigationLink(
            destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel, backgroundColor: backgroundColor, patientName: patientName ?? "General Chat", calledFromPatientContext: false)
              .modelContext(modelContext),
            isActive: $isNavigatingToNewSession
          ) {
            EmptyView()
          }
        )
      }
    }
  }
  
  // MARK: - Header View

  private var headerView: some View {
      VStack(alignment: .leading, spacing: 4) {
      //  if UIDevice.current.userInterfaceIdiom == .phone {
          HStack {
            Button(action: {
              dismiss()
            }) {
              HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                  .font(.system(size: 21, weight: .medium))
                  .foregroundColor(.blue)
                Text("Back")
                  .font(.system(size: 18))
                  .foregroundColor(.blue)
              }
            }
            .contentShape(Rectangle())
            Spacer()
          }
          .padding(.leading, 10)
          .padding(.top, 9)
       // }
          HStack {
              Text(SetUIComponents.shared.chatHistoryTitle ?? "Chat History")
                  .foregroundColor(.black)
                  .font(.custom("Lato-Bold", size: 34))
                  .padding(.leading, 16)
                  .padding(.top, 16)
              Spacer()
          }
      }
      .padding(.bottom, 5)
  }
  
  private var mainContentView: some View {
    Group {
      if thread.isEmpty {
        emptyStateView
      } else {
        threadListView
      }
    }
  }

  // MARK: - Empty State View
  private var emptyStateView: some View {
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

  private var threadListView: some View {
    VStack {
      Divider()
      ScrollView {
        VStack() {
          ForEach(Array(thread.enumerated()), id: \.element.id) { index, thread in
            threadItemView(for: thread)
          }
        }
        .padding(.horizontal)
      }
      .background(navigationLinkToNewSession)
      .contentMargins(.top, 0, for: .scrollContent)
    }
  }

  private func threadItemView(for thread: SessionDataModel) -> some View {
      Button(action: {
          if selectedSessionId != thread.sessionId {
              newSessionId = nil
          }
          viewModel.vmssid = thread.sessionId
          selectedSessionId = thread.sessionId
        do {
          let patient = try fetchPatientName(fromSessionId: thread.sessionId, context: DatabaseConfig.shared.modelContext)
          patientName = patient
        } catch {
          print("No patient name found")
        }
          isNavigating = true
      }) {
          MessageSubView(
              thread.title,
              viewModel.getFormatedDateToDDMMYYYY(date: thread.lastUpdatedAt),
              thread.subTitle,
              foregroundColor: (newSessionId == thread.sessionId) ||
              (selectedSessionId == thread.sessionId && newSessionId == nil) ? true : false
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
      .buttonStyle(PlainButtonStyle())
  }

  // MARK: - Navigation Link
  private var navigationLinkToNewSession: some View {
      NavigationLink(
          destination: destinationView,
          isActive: $isNavigating
      ) {
          EmptyView()
      }
  }

  private var destinationView: some View {
      if let sessionId = selectedSessionId {
          return AnyView(
              NewSessionView(
                  session: sessionId,
                  viewModel: viewModel,
                  backgroundColor: backgroundColor, patientName: patientName ?? "",
                  calledFromPatientContext: false
              )
              .modelContext(modelContext)
          )
      } else {
          return AnyView(EmptyView())
      }
  }

  private var editButtonView: some View {
    VStack {
      Spacer()
      HStack() {
        if UIDevice.current.userInterfaceIdiom == .phone {
          Spacer()
        }
        Button(action: {
          _ = viewModel.createSession(subTitle: "General Chat")
          newSessionId = viewModel.vmssid
          isNavigatingToNewSession = true
        }) {
          if let newChatButtonImage = SetUIComponents.shared.newChatButtonImage {
            Image(uiImage: newChatButtonImage)
              .resizable()
              .scaledToFit()
              .frame(width: 18)
          } else {
            Image(systemName: "square.and.pencil")
              .resizable()
              .font(.title2)
              .foregroundColor(.white)
              .background(editButtonColor)
              .clipShape(Circle())
              .shadow(radius: 10)
              .scaledToFit()
              .frame(width: 18)
          }
          
          if let newChatButtonText = SetUIComponents.shared.newChatButtonText {
            Text(newChatButtonText)
              .foregroundColor(Color.blue)
              .font(.custom("Lato-Bold", size: 18))
          }
        }
        .frame(maxWidth: thread.isEmpty ? .infinity : 160)
        .padding(.vertical, 14)
        .padding(.horizontal, 5)
        .background(Color.white)
        .cornerRadius(10)
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
        }
        .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 8)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
          Spacer()
        }
      }
      .padding(.bottom, 20)
    }
  }
  
  // MARK: - Message SubView
  func MessageSubView(_ title: String, _ date: String, _ subTitle: String?, foregroundColor: Bool) -> some View {
    VStack {
      HStack {
        nameInitialsView(initials: getInitials(name: subTitle ?? "GeneralChat") ?? "GC")
        VStack (spacing: 6) {
          HStack {
            Text(subTitle ?? "GeneralChat")
              .font(.custom("Lato-Regular", size: 16))
              .foregroundColor(UIDevice.current.userInterfaceIdiom == .pad ? (foregroundColor ? .white : .primary) : .primary)
              .lineLimit(1)
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
            Text(title)
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
  
  private func nameInitialsView(initials: String) -> some View {
    ZStack {
      LinearGradient(
          colors: [
              Color(red: 186/255, green: 186/255, blue: 186/255, opacity: 1.0),
              Color(red: 161/255, green: 161/255, blue: 161/255, opacity: 1.0)
          ],
          startPoint: .top,
          endPoint: .bottom
      )
        .frame(width: 38, height: 38)
      Text(initials)
        .foregroundStyle(.white)
        .font(.custom("Lato-Bold", size: 16))
        .fontWeight(.bold)
    }
    .clipShape(Circle())
  }
}

public struct SomeMainView: View {
  
  var backgroundColor: Color?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  var ctx: ModelContext
  var delegate: ConvertVoiceToText
  
  public init(
    backgroundColor: Color? = .white,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    subTitle: String? = "General Chat",
    ctx: ModelContext,
    delegate: ConvertVoiceToText
  ) {
    self.backgroundColor = backgroundColor
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.ctx = ctx
    self.delegate = delegate
    
    DatabaseConfig.shared.modelContext = ctx
  }
  
  public var body: some View {
    MainView(backgroundColor: backgroundColor, emptyMessageColor: emptyMessageColor, editButtonColor: editButtonColor, subTitle: subTitle, ctx: ctx, delegate: delegate)
      .modelContext(ctx)
      .navigationBarHidden(true)
  }
}

func getInitials(name: String?) -> String? {
  name?.uppercased().components(separatedBy: " ").reduce("") { $0 + $1.prefix(1) }
}

public protocol ConvertVoiceToText {
  func convertVoiceToText(audioFileURL: URL, completion: @escaping (String) -> Void)
}
