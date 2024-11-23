//
//  NewSessionView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

struct NewSessionView: View {
  var session: String
  @State var newMessage: String = ""
  @Query private var messages: [ChatMessageModel]
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundImage: UIImage?
  @FocusState private var isTextFieldFocused: Bool
  
  init(session: String, viewModel: ChatViewModel, backgroundImage: UIImage?) {
    self.session = session
    _messages = Query(
      filter: #Predicate<ChatMessageModel> { message in
        message.sessionData?.sessionId == session
      },
      sort: \.msgId,
      order: .forward
    )
    self.viewModel = viewModel
    self.backgroundImage = backgroundImage
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      newView
    }
  }
  
  var newView: some View {
    ZStack {
      if let backgroundImage = backgroundImage {
        Image(uiImage: backgroundImage)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
          .ignoresSafeArea()
      }
      
      VStack {
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack {
              ForEach(messages) { message in
                MessageBubble(message: message, m: message.messageText ?? "")
                  .padding(.horizontal)
                  .padding(.top, message == messages.first ? 20 : 0)
              }
            }
            .padding(.top, 10)
          }
        }

        textfieldView()
          .padding(.bottom, 5)
      }
      .navigationTitle("Chat")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
  
  private func textfieldView() -> some View {
      HStack {
          Image(systemName: "magnifyingglass")
              .foregroundColor(.gray)
              .padding(.leading, 10)

          TextField("Start typing here...", text: $newMessage)
              .padding(12)
              .background(Color.white)
              .cornerRadius(30)
              .font(.body)
              .frame(height: 48)
              .padding(.horizontal, 8)
              .focused($isTextFieldFocused)
              .onTapGesture {
                  isTextFieldFocused = true
              }

          Button(action: {
              guard !newMessage.isEmpty else { return }
              sendMessage(newMessage)
              isTextFieldFocused = false // Dismiss keyboard after sending
          }) {
              Image(systemName: "paperplane.fill")
                  .foregroundColor(.white)
                  .padding(12)
                  .background(newMessage.isEmpty ? Color.gray : Color.blue)
                  .clipShape(Circle())
                  .shadow(radius: 5)
          }
          .disabled(newMessage.isEmpty)
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 16)
  }

  private func sendMessage(_ message: String) {
    viewModel.vmssid = session
    viewModel.sendMessage(newMessage: message)
    newMessage = ""
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
        Text(m)
          .padding(12)
          .background(
            message.role == .user ? Color.blue : Color.gray.opacity(0.2)
          )
          .foregroundColor(
            message.role == .user ? .white : .primary
          )
          .cornerRadius(16)
          .animation(
            .easeInOut,
            value: message.messageText
          )
      }
      
      if message.role == .Bot {
        Spacer()
      }
    }
    .padding(.horizontal)
    .padding(.top, 4)
  }
}
