//
//  MainView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//


import SwiftUI
import SwiftData

public struct MainView: View {
  
  public init() {
  }
  
  @Query(sort: \SessionDataModel.createdAt, order: .reverse) var thread: [SessionDataModel]
  var queryParams: [String: String] = [
    "d_oid": "161467756044203",
    "d_hash": "6d36c3ca25abe7d9f34b81727f03d719",
    "pt_oid": "161857870651607"
  ]
  @StateObject var viewModel = ChatViewModel(networkConfig: NetworkConfiguration(baseUrl: "https://lucid-ws.eka.care/doc_chat/v1/stream_chat", queryParams: [:], httpMethod: "POST"))
  @State private var newSessionId: String? = nil
  @State private var isNavigatingToNewSession: Bool = false
  @Environment(\.modelContext) var modelContext
  
  public var body: some View {
    NavigationView {
      ZStack {
        VStack {
          if thread.isEmpty {
            Text("No messages yet")
              .font(.title2)
              .fontWeight(.medium)
              .foregroundColor(.gray)
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              .padding()
          } else {
            List {
              ForEach(thread) { thread in
                NavigationLink {
                  NewSessionView(session: thread.sessionId, viewModel: viewModel)
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
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 10)
            }
            .padding(.bottom, 16)
            .padding(.trailing, 16)
          }
        }
      }
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .onAppear() {
        viewModel.netWorkConfig.queryParams = queryParams
      }
      
      .background(
        NavigationLink(
          destination: NewSessionView(session: newSessionId ?? "", viewModel: viewModel)
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
  public init() { }
  public var body: some View {
    MainView()
      .modelContext(QueueConfigRepo.shared.modelContext)
  }
}
