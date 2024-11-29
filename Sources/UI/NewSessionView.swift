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
      if let backgroundImage {
        newView
          .background(Image(uiImage: backgroundImage))
        
      } else {
        newView
      }
    }
  }
  
  var newView: some View {
    VStack {
      if messages.isEmpty {
        VStack {
          Spacer()
          if let image = SetUIComponents.shared.emptyChatImage {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(width: 60)
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
  
  var textfieldView: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 30)
        .fill(Color.white)
      
      HStack {
        TextField("  Start typing...", text: $newMessage)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .font(.body)
          .focused($isTextFieldFocused)
          .onTapGesture {
            isTextFieldFocused = true
          }
        
        Button(action: {
          newMessage = viewModel.trimLeadingSpaces(from: newMessage)
          guard !newMessage.isEmpty else { return }
          sendMessage(newMessage)
          isTextFieldFocused = false
          viewModel.returnFromNewSessionWithTyping = true
        }) {
          Image(systemName: "paperplane.fill")
            .foregroundStyle(newMessage.isEmpty ? Color.gray : Color.blue)
            .padding(10)
            .background(Circle().fill(Color.white))
        }
        .disabled(newMessage.isEmpty)
      }
      .padding(.horizontal, 12)
    }
    .frame(height: 48)
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
    HStack(alignment: .top) {
      if message.role == .user {
        Spacer()
      }
      
      if message.role == .Bot {
        BotAvatarImage()
          .alignmentGuide(.top) { d in d[.top] }
      }
      
      MessageTextView(text: m, role: message.role)
        .alignmentGuide(.top) { d in d[.top] }
      
      if message.role == .user {
        UserAvatarImage()
          .alignmentGuide(.top) { d in d[.top] }
      }
      
      if message.role == .Bot {
        Spacer()
      }
    }
    .padding(.top, 4)
  }
}

struct MessageTextView: View {
  let text: String
  let role: MessageRole
  
  var body: some View {
    Text(.init(text))
      .padding(8)
      .background(backgroundColor)
      .foregroundColor(foregroundColor)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(SetUIComponents.shared.chatBorder ?? Color.gray, lineWidth: 0.3)
      )
      .contentTransition(.numericText())
  }
  
  private var backgroundColor: Color {
    role == .user ? (SetUIComponents.shared.userBackGroundColor ?? .blue) : (SetUIComponents.shared.botBackGroundColor ?? .gray)
  }
  
  private var foregroundColor: Color {
    role == .user ? (SetUIComponents.shared.usertextColor ?? .black) : (SetUIComponents.shared.botTextColor ?? .white)
  }
}

struct BotAvatarImage: View {
  var body: some View {
    if let image = SetUIComponents.shared.chatIcon {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .frame(width: 20)
    }
  }
}

struct UserAvatarImage: View {
  var body: some View {
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
