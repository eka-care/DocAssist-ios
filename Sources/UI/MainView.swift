//
//  MainView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

struct MainView: View {
  
  @Query(sort: \SessionDataModel.createdAt, order: .reverse) var thread: [SessionDataModel]
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
  var subTitle: String?
  
  init(backgroundColor: Color? = nil, emptyMessageColor: Color? = .white, editButtonColor: Color? = .blue, subTitle: String? = "General Chat", ctx: ModelContext) {
    self.backgroundColor = backgroundColor
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.viewModel = ChatViewModel(context: ctx)
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
          destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel, backgroundColor: backgroundColor, patientName: subTitle ?? "General Chat")
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
            destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel, backgroundColor: backgroundColor, patientName: subTitle ?? "General Chat")
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
        if UIDevice.current.userInterfaceIdiom == .phone {
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
        }
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
            VStack {
              Divider()
              threadListView
            }
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
      ScrollView {
          VStack() {
            ForEach(Array(thread.enumerated()), id: \.element.id) { index, thread in
              threadItemView(for: thread)
                           .padding(.top, index == 0 ? 20 : 0)
                   }
          }
          .padding(.horizontal)
      }
      .background(navigationLinkToNewSession)
  }

  private func threadItemView(for thread: SessionDataModel) -> some View {
      Button(action: {
      
          if selectedSessionId != thread.sessionId {
              newSessionId = nil
          }
          
          viewModel.vmssid = thread.sessionId
          selectedSessionId = thread.sessionId
          isNavigating = true
      }) {
          MessageSubView(
              thread.title,
              viewModel.getFormatedDateToDDMMYYYY(date: thread.createdAt),
              thread.subTitle
          )
          .background(Color.clear)
          .background(
              RoundedRectangle(cornerRadius: 10)
                  .fill(Color.clear)
          )
          .overlay(
              UIDevice.current.userInterfaceIdiom == .pad ?
                  RoundedRectangle(cornerRadius: 10)
                      .stroke(
                          (newSessionId == thread.sessionId) ||
                          (selectedSessionId == thread.sessionId && newSessionId == nil) ? Color.blue : Color.clear,
                          lineWidth: 1
                      )
                  : nil
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
                  backgroundColor: backgroundColor, patientName: ""
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
          _ = viewModel.createSession(subTitle: subTitle)
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
        .background(Color.white)
        .cornerRadius(10)
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color.blue, lineWidth: 0.5)
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
  func MessageSubView(_ title: String, _ date: String, _ subTitle: String?) -> some View {
    VStack {
      HStack {
        Text(subTitle ?? "GeneralChat")
          .font(.custom("Lato-Regular", size: 16))
          .foregroundColor(.primary)
          .lineLimit(1)
        Spacer()
          Text(date)
            .font(.caption)
            .foregroundStyle(Color.gray)
          Image(systemName: "chevron.right")
            .resizable()
            .scaledToFit()
            .frame(width: 7)
            .foregroundStyle(Color.gray)
      }
      HStack {
        Text(title)
          .font(.caption)
          .foregroundStyle(Color.gray)
          .lineLimit(1)
        Spacer()
      }
      Divider()
    }
  }
}

public struct SomeMainView: View {
  
  var backgroundColor: Color?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  var ctx: ModelContext
  
  public init(
    backgroundColor: Color? = .white,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    subTitle: String? = "General Chat",
    ctx: ModelContext
  ) {
    self.backgroundColor = backgroundColor
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.ctx = ctx
    
    DatabaseConfig.shared.modelContext = ctx
  }
  
  public var body: some View {
    MainView(backgroundColor: backgroundColor, emptyMessageColor: emptyMessageColor, editButtonColor: editButtonColor, subTitle: subTitle, ctx: ctx)
      .modelContext(ctx)
      .navigationBarHidden(true)
  }
}
