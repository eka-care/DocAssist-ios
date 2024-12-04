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
  @State private var selectedSessionId: String? = nil
  @State private var isNavigating: Bool = false
  private var bgcolors: Color
  var backgroundImage: UIImage?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  
  public init(backgroundImage: UIImage? = nil, emptyMessageColor: Color? = .white, editButtonColor: Color? = .blue, subTitle: String? = "General Chat", ctx: ModelContext) {
    self.backgroundImage = backgroundImage
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.viewModel = ChatViewModel(context: ctx)
    self.bgcolors = SetUIComponents.shared.emptyHistoryBgColor ?? Color.gray
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
              .padding(.trailing, 20)
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
        
          HStack {
              Text(SetUIComponents.shared.chatHistoryTitle ?? "Chat History")
                  .foregroundColor(.black)
                  .font(.custom("Lato-Bold", size: 34))
                  .padding(.leading, 16)
                  .padding(.top, 16)
              Spacer()
          }
      }
      .padding(.bottom, 8)
  }
 

  private var mainContentView: some View {
    Group {
      // MARK: - Make this generic
      if thread.isEmpty {
        ZStack {
          bgcolors
            .ignoresSafeArea()
          VStack {
            HStack {
              Text("Start a new chat with Doc Assist to-")
                .fontWeight(.medium)
                .font(.custom("Lato-Regular", size: 18))
                .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
                .padding(.leading , 20)
                .padding(.top, 25)
                Spacer()
            }
            HStack {
              Text("""
      💊 Confirm drug interactions
      🥬 Generate diet charts
      🏋️‍♀️ Get lifestyle advice for a patient
      📃 Generate medical certificate templates
      and much more..
      """)
              .padding(.leading , 20)
              .padding(.top, 5)
              .foregroundStyle(SetUIComponents.shared.emptyHistoryFgColor ?? Color.gray)
              Spacer()
            }
            Spacer()
          }
        }
      
      } else {
        List {
          ForEach(thread) { thread in
            let dateString = viewModel.getFormatedDateToDDMMYYYY(date: thread.createdAt)
            MessageSubView(thread.title,dateString,thread.subTitle)
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
              .onTapGesture {
                viewModel.vmssid = thread.sessionId
              }
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
      HStack(spacing: 6) {
        Spacer()
        Button(action: {
          viewModel.createSession(subTitle: subTitle)
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
        .cornerRadius(16)
        .overlay {
          RoundedRectangle(cornerRadius: 16)
            .stroke(Color.blue, lineWidth: 0.5)
        }
      }
      .padding(.bottom, 20)
    }
  }
  
  // MARK: - Message SubView
  func MessageSubView(_ title: String, _ date: String, _ subTitle: String?) -> some View {
    VStack {
      HStack {
        Text(title)
          .font(.custom("Lato-Regular", size: 16))
          .foregroundColor(.primary)
          .lineLimit(1)
        Spacer()
        Text(date)
          .font(.caption)
          .foregroundStyle(Color.gray)
      }
      HStack {
        Text(subTitle ?? "")
          .font(.caption)
          .foregroundStyle(Color.gray)
        Spacer()
      }
    }
    .padding(.all, 10)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.white)
    )
  }
}

public struct SomeMainView: View {
  
  var backgroundImage: UIImage?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  var subTitle: String?
  var ctx: ModelContext
  
  public init(
    backgroundImage: UIImage? = nil,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    subTitle: String? = "General Chat",
    ctx: ModelContext
  ) {
    self.backgroundImage = backgroundImage
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.subTitle = subTitle
    self.ctx = ctx
    
    QueueConfigRepo1.shared.modelContext = ctx
  }
  
  public var body: some View {
    MainView(backgroundImage: backgroundImage, emptyMessageColor: emptyMessageColor, editButtonColor: editButtonColor, subTitle: subTitle, ctx: ctx)
      .modelContext(ctx)
      .navigationBarHidden(true)
  }
}
