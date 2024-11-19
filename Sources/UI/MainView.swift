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
  var queryParams: [String: String] = [
        "d_oid": "161467756044203",
        "d_hash": "6d36c3ca25abe7d9f34b81727f03d719",
        "pt_oid": "161857870651607"
    ]
  @StateObject var viewModel = ChatViewModel(networkConfig: NetworkConfiguration(baseUrl: "https://lucid-ws.eka.care/doc_chat/v1/stream_chat", queryParams: [:], httpMethod: "POST"))

  @Environment(\.modelContext) var modelContext
  public var body: some View {
        NavigationView {
            VStack {
                // Header
                VStack(alignment: .leading) {
                    HStack {
                        Text("ChatBot")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.leading)
                            .padding(.top, 16)
                        Spacer()
                        Button(action: {
                          viewModel.createSession()
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .padding(10)
                        }
                    }
                    .padding(.bottom, 16)
                }
                
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
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .onAppear() {
              viewModel.netWorkConfig.queryParams = queryParams
            }
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
