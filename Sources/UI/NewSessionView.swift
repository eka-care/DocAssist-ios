//
//  NewSessionView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
#if canImport(SwiftData)
import SwiftData
#endif

struct NewSessionView: View {
  
  var session: String
  @State var newMessage: String = ""
  @Query private var messages: [ChatMessageModel]
  @ObservedObject private var viewModel: ChatViewModel
  
  init(session: String, viewModel: ChatViewModel) {
    
    self.session = session
    _messages = Query(
      filter: #Predicate<ChatMessageModel> { message in
        message.sessionData?.sessionId == session
      },
      sort: \.msgId,
      order: .forward
    )
    
    self.viewModel = viewModel
  }
  
  var body: some View {
    VStack {

      ScrollViewReader { proxy in
        List {
          ForEach(messages) { message in
            MessageBubble(message: message, m: message.messageText ?? "")
          }
        }
        .listStyle(.plain) 
        .padding(.top)
      }
      
      HStack {
        TextField("Type a message...", text: $newMessage)
          .textFieldStyle(RoundedBorderTextFieldStyle()) // Round the text field
          .padding(.leading, 10)
          .padding(.vertical, 8)
          .frame(height: 40)
          .background(Color.white)
          .cornerRadius(20)
          .shadow(radius: 2)

        Button(action: {
          viewModel.vmssid = session
          viewModel.sendMessage(newMessage: newMessage)
          newMessage = ""
        }) {
          Image(systemName: "arrow.up.circle.fill")
            .font(.title)
            .foregroundColor(.blue)
        }
        .disabled(newMessage.isEmpty)
        .padding(.trailing, 10)
      }
      .background(Color(UIColor.systemGray6))
      .cornerRadius(30)
      .padding(.horizontal)
      .padding(.bottom, 10)
    }
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct MessageBubble: View {
  let message: ChatMessageModel
  let m: String
  
  var body: some View {
    HStack {
      if message.role == .user {
        Spacer()
      }
      
      VStack(
        alignment: message.role == .user ? .trailing : .leading
      ) {
        Text(
          .init(m)
          
        )
        .padding()
        .background(
          message.role == .user ? Color.blue : Color.gray.opacity(
            0.2
          )
        )
        .foregroundColor(
          message.role == .user ? .white : .primary
        )
        .cornerRadius(
          16
        )
        .animation(
          .easeInOut,
          value: message.messageText
        )
      }
      
      if message.role == .Bot {
        Spacer()
      }
    }
  }
}


