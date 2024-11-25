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
  var backButtonColor: Color?
  
  public init(backgroundImage: UIImage? = nil, emptyMessageColor: Color? = .white, editButtonColor: Color? = .blue, backButtonColor: Color?, ctx: ModelContext) {
    self.backgroundImage = backgroundImage
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.backButtonColor = backButtonColor
    
    self.viewModel = ChatViewModel(context: ctx)
  }

  public var body: some View {
    NavigationView {
      ZStack {
        if let backgroundImage = backgroundImage {
          Image(uiImage: backgroundImage)
            .resizable()
            .scaledToFill()
            .edgesIgnoringSafeArea(.all)
        } else {
          Color.white
            .edgesIgnoringSafeArea(.all)
        }

        VStack {
          headerView
          mainContentView
          Spacer()
          editButtonView
        }
        .padding(.top, 45)
        .navigationBarHidden(true) // Hide default navigation bar
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
    
     HStack {
       Button(action: {
         dismiss()
       }) {
         HStack {
           Image(systemName: "chevron.left")
             .font(.title3)
             .foregroundColor(backButtonColor ?? .black)
         }
         .padding(.leading, 5)
       }
       Text("Chat History")
         .foregroundColor(backButtonColor ?? .black)
       Spacer()
     }
  }

  private var mainContentView: some View {
    Group {
      if thread.isEmpty {
        Text("No messages yet")
          .font(.title2)
          .fontWeight(.medium)
          .foregroundColor(emptyMessageColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
          .padding()
      } else {
        List {
          ForEach(thread) { thread in
            NavigationLink {
              NewSessionView(session: thread.sessionId, viewModel: viewModel, backgroundImage: backgroundImage)
                .modelContext(modelContext)
            } label: {
              MessageSubView(thread.title)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button(role: .destructive) {
                QueueConfigRepo1.shared.deleteSession(sessionId: thread.sessionId)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(.plain)
        .padding(.top, 20)
      }
    }
  }

  // MARK: - Floating Edit Button
  private var editButtonView: some View {
    HStack {
      Spacer()
      
      Button(action: {
        viewModel.createSession()
        newSessionId = viewModel.vmssid
        isNavigatingToNewSession = true
      }) {
        Image(systemName: "square.and.pencil")
          .font(.title2)
          .foregroundColor(.white)
          .padding()
          .background(editButtonColor)
          .clipShape(Circle())
          .shadow(radius: 10)
      }
      .padding(.bottom, 40)
      .padding(.trailing, 16)
    }
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
  var backButtonColor: Color?
  var ctx: ModelContext
  
  public init(
    backgroundImage: UIImage? = nil,
    emptyMessageColor: Color? = .white,
    editButtonColor: Color? = .blue,
    backButtonColor: Color?,
    ctx: ModelContext
  ) {
    self.backgroundImage = backgroundImage
    self.emptyMessageColor = emptyMessageColor
    self.editButtonColor = editButtonColor
    self.backButtonColor = backButtonColor
    self.ctx = ctx
    
    QueueConfigRepo1.shared.modelContext = ctx
  }
  
  public var body: some View {
    MainView(backgroundImage: backgroundImage, emptyMessageColor: emptyMessageColor, editButtonColor: editButtonColor, backButtonColor: backButtonColor, ctx: ctx)
  //    .modelContext(QueueConfigRepo.shared.modelContext)
      .modelContext(ctx)
      .navigationBarHidden(true)
  }
}
