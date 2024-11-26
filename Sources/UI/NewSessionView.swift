//
//  NewSessionView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

struct NewSessionView: View {
  @State var session: String
  @State var newMessage: String = ""
  @Query private var messages: [ChatMessageModel]
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundImage: UIImage?
  @FocusState private var isTextFieldFocused: Bool
  @State private var scrollToBottom = false
  
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
                  .scaledToFill()
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                  .ignoresSafeArea()
          }

          VStack {
              if messages.isEmpty {
                VStack {
                  Spacer()
                  if let image = SetUIComponents.shared.emptyChatImage {
                    Image(uiImage: image)
                      .resizable()
                      .scaledToFit()
                      .frame(width: 100)
                  }
                  Text(SetUIComponents.shared.emptyChatTitle ?? "No Chat yet")
                    .foregroundColor(.black)
                    .font(.title3)
                    .padding()
                  Spacer()
                  textfieldView
                      .padding(.bottom, 5)
                }
              } else {
                  ScrollViewReader { proxy in
                      ScrollView {
                          LazyVStack {
                              ForEach(messages) { message in
                                  MessageBubble(message: message, m: message.messageText ?? "")
                                      .padding(.horizontal)
                                      .padding(.top, message == messages.first ? 20 : 0)
                                      .id(message.id)
                              }
                              Color.clear
                                  .frame(height: 1)
                                  .id("bottomID")
                          }
                          .padding(.top, 10)
                      }
                      .onChange(of: messages.count) { _, _ in
                          withAnimation(.easeOut(duration: 0.3)) {
                              proxy.scrollTo("bottomID", anchor: .bottom)
                          }
                      }
                      .onChange(of: isTextFieldFocused) { focused, _ in
                          if focused {
                              withAnimation(.easeOut(duration: 0.3)) {
                                  proxy.scrollTo("bottomID", anchor: .bottom)
                              }
                          }
                      }
                      .simultaneousGesture(
                          DragGesture().onChanged { _ in
                              if isTextFieldFocused {
                                  isTextFieldFocused = false
                              }
                          }
                      )
                      .onAppear {
                          proxy.scrollTo("bottomID", anchor: .bottom)
                      }
                  }
                textfieldView
                    .padding(.bottom, 5)
              }
          }
          .navigationTitle(SetUIComponents.shared.chatTitle ?? "Chats")
          .navigationBarTitleDisplayMode(.inline)
      }
  }

  
  var textfieldView : some View {
    ZStack {
      HStack {
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
      }
      HStack {
        Spacer()
        Button(action: {
          newMessage = viewModel.trimLeadingSpaces(from: newMessage)
          guard !newMessage.isEmpty else { return }
          sendMessage(newMessage)
          isTextFieldFocused = false
        }) {
          Image(systemName: "paperplane.fill")
            .padding(10)
            .foregroundStyle(newMessage.isEmpty ? Color.gray : Color.blue)
            .clipShape(Circle())
        }
        .disabled(newMessage.isEmpty)
        
      }
      .padding()
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
        HStack {
          if message.role == .Bot {
            if let image = SetUIComponents.shared.chatIcon {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 35)
                .cornerRadius(15)
            }
          }
            Text(.init(m))
              .padding(8)
              .background(
                message.role == .user ? SetUIComponents.shared.userBackGroundColor ?? .blue : SetUIComponents.shared.botBackGroundColor ?? .gray
              )
              .foregroundColor(
                message.role == .user ? SetUIComponents.shared.usertextColor ?? .black : SetUIComponents.shared.botTextColor ?? .white
              )
              .cornerRadius(16)
              .animation(
                .easeInOut,
                value: message.messageText
              )
          
          if message.role == .user {
            if let image = SetUIComponents.shared.userIcon {
              Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 35)
                .cornerRadius(15)
                .foregroundStyle(Color.gray)
            }
          }
        }
      }
      
      if message.role == .Bot {
        Spacer()
      }
    }
    .padding(.top, 4)
  }
}
