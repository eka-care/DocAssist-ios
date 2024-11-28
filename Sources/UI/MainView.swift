//
//  MainView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

public struct MainView: View {
  
  @Query(sort: \SessionDataModel.createdAt, order: .reverse) var thread: [SessionDataModel]
  @ObservedObject var viewModel: ChatViewModel
  @State private var newSessionId: String? = nil
  @State private var isNavigatingToNewSession: Bool = false
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  
  var backgroundImage: UIImage?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  
  public init(backgroundImage: UIImage? = nil, emptyMessageColor: Color? = .white, editButtonColor: Color? = .blue, ctx: ModelContext) {
    self.backgroundImage = backgroundImage
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    
    self.viewModel = ChatViewModel(context: ctx)
  }

  public var body: some View {
    NavigationView {
      ZStack {
        if let backgroundImage = SetUIComponents.shared.userAllChatBackgroundColor {
          Image(uiImage: backgroundImage)
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
        }
        VStack {
          headerView
          ZStack {
            mainContentView
            editButtonView
          }
          
        }
        .navigationBarHidden(true)
      }
      .background(
        NavigationLink(
          destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel, backgroundImage: backgroundImage)
            .modelContext(modelContext),
          isActive: $isNavigatingToNewSession
        ) {
          EmptyView()
        }
      )
    }
  }
  
  // MARK: - Header View

  private var headerView: some View {
      VStack(alignment: .leading, spacing: 4) {
          HStack {
              Button(action: {
                  dismiss()
              }) {
                  HStack(spacing: 6) {
                      Image(systemName: "chevron.left")
                      .font(.system(size: 19, weight: .medium))
                          .foregroundColor(.blue)
                      Text("Back")
                          .font(.system(size: 16))
                          .foregroundColor(.blue)
                  }
              }
              .contentShape(Rectangle())
              Spacer()
          }
          .padding(.leading, 10)
          .padding(.top, 9)
        
          HStack {
              Text(SetUIComponents.shared.chatHistoryTitle ?? "Chat History")
                  .foregroundColor(.black)
                  .font(.system(size: 28, weight: .medium))
                  .padding(.leading, 16)
              Spacer()
          }
      }
      .padding(.bottom, 8)
  }
 

  private var mainContentView: some View {
    Group {
      if thread.isEmpty {
        Text("No chats yet")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(Color.blue)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          .padding()
      } else {
        List {
          ForEach(thread) { thread in
            MessageSubView(thread.title)
              .background(
                NavigationLink(
                  destination: NewSessionView(session: thread.sessionId, viewModel: viewModel, backgroundImage: backgroundImage)
                    .modelContext(modelContext),
                  label: {
                    EmptyView()
                  }
                )
                .opacity(0)
              )
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
              .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                  QueueConfigRepo1.shared.deleteSession(sessionId: thread.sessionId)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
          }
        }
      }
    }
  }

  // MARK: - Floating Edit Button
  private var editButtonView: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button(action: {
          viewModel.createSession()
          newSessionId = viewModel.vmssid
          isNavigatingToNewSession = true
        }) {
          if let newChatButtonImage = SetUIComponents.shared.newChatButtonImage {
            Image(uiImage: newChatButtonImage)
              .resizable()
              .frame(width: 35, height: 35)
          } else {
            Image(systemName: "square.and.pencil")
              .font(.title2)
              .foregroundColor(.white)
              .padding()
              .background(editButtonColor)
              .clipShape(Circle())
              .shadow(radius: 10)
          }
          
          if let newChatButtonText = SetUIComponents.shared.newChatButtonText {
            Text(newChatButtonText)
              .foregroundColor(.black)
              .padding(.trailing, 5)
          }
        }
        .frame(width: 200, height: 60)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(radius: 10)
      }
    }
    .padding(.trailing, 10)
  }

  // MARK: - Message SubView
  func MessageSubView(_ title: String) -> some View {
    HStack {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)
        .lineLimit(1)
      Spacer()
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    )
  }
}

public struct SomeMainView: View {
  
  var backgroundImage: UIImage?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var ctx: ModelContext
  
  public init(
    backgroundImage: UIImage? = nil,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    ctx: ModelContext
  ) {
    self.backgroundImage = backgroundImage
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.ctx = ctx
    
    QueueConfigRepo1.shared.modelContext = ctx
  }
  
  public var body: some View {
    MainView(backgroundImage: backgroundImage, emptyMessageColor: emptyMessageColor, editButtonColor: editButtonColor, ctx: ctx)
      .modelContext(ctx)
      .navigationBarHidden(true)
  }
}

