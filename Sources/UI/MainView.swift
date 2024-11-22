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
//  var queryParams: [String: String] = [
//    "d_oid": "161467756044203",
//    "d_hash": "6d36c3ca25abe7d9f34b81727f03d719",
//    "pt_oid": "161857870651607"
//  ]
//  @StateObject var viewModel = ChatViewModel(networkConfig: NetworkConfiguration(baseUrl: "https://lucid-ws.eka.care/doc_chat/v1/stream_chat", queryParams: [:], httpMethod: "POST"))
  @StateObject var viewModel = ChatViewModel()
  @State private var newSessionId: String? = nil
  @State private var isNavigatingToNewSession: Bool = false
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss
  
  var backgroundImage: UIImage?
  var emptyMessageColor: Color?
  var editButtonColor: Color?
  
  public init(backgroundImage: UIImage? = nil, emptyMessageColor: Color? = .white, editButtonColor: Color? = .blue) {
     self.backgroundImage = backgroundImage
     self.emptyMessageColor = emptyMessageColor
     self.editButtonColor = editButtonColor
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
        
        ZStack {
          VStack {
            HStack {
              Button(action: {
                dismiss()
              }) {
                HStack {
                  Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
                  Text("Back")
                    .foregroundColor(.blue)
                    .font(.body)
                }
              }
              .padding(.leading, 16)
              
              Spacer()
            }
            
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
                      QueueConfigRepo.shared.deleteSession(sessionId: thread.sessionId)
                    } label: {
                      Label("Delete", systemImage: "trash")
                    }
                  }
                }
              }
              .listStyle(.plain)
            }
            
            Spacer()
          }
          
          VStack {
            Spacer()
            
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
              .padding(.bottom, 16)
              .padding(.trailing, 16)
            }
          }
        }
      }
      .onAppear() {
    //    viewModel.netWorkConfig.queryParams = queryParams
      }
      .background(
        NavigationLink(
          destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel,backgroundImage: backgroundImage)
            .modelContext(modelContext),
          isActive: $isNavigatingToNewSession
        ) {
          EmptyView()
        }
      )
    }
  }
  
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
  var empytyMessageColor: Color?
  var editButtonColor: Color?
  
  public init(backgroundImage: UIImage? = nil, emptymessageColor: Color?, editButtonColor: Color?) {
    self.backgroundImage = backgroundImage
    self.empytyMessageColor = emptymessageColor
    self.editButtonColor = editButtonColor
  }
  
  public var body: some View {
    MainView(backgroundImage: backgroundImage, emptyMessageColor: empytyMessageColor, editButtonColor: editButtonColor)
      .modelContext(QueueConfigRepo.shared.modelContext)
      .navigationBarHidden(true)
  }
}
