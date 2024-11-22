//
//  NewSessionView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

//struct NewSessionView: View {
//
//  var session: String
//  @State var newMessage: String = ""
//  @Query private var messages: [ChatMessageModel]
//  @ObservedObject private var viewModel: ChatViewModel
//  var backgroundImage: UIImage?
//
//  init(session: String, viewModel: ChatViewModel, backgroundImage: UIImage?) {
//    self.session = session
//    _messages = Query(
//      filter: #Predicate<ChatMessageModel> { message in
//        message.sessionData?.sessionId == session
//      },
//      sort: \.msgId,
//      order: .forward
//    )
//    self.viewModel = viewModel
//    self.backgroundImage = backgroundImage
//  }
//
//  var body: some View {
//    GeometryReader { geometry in
//      ZStack {
//
//        // Background Image or Color
//        if let backgroundImage = backgroundImage {
//          Image(uiImage: backgroundImage)
//            .resizable()
//            .scaledToFill()
//            .frame(width: geometry.size.width, height: geometry.size.height)
//            .edgesIgnoringSafeArea(.all)
//        } else {
//          Color.white
//            .edgesIgnoringSafeArea(.all)
//        }
//
//        VStack {
//          // Message List Section
//          ScrollViewReader { proxy in
//            ScrollView {
//              LazyVStack {
//                ForEach(messages) { message in
//                  MessageBubble(message: message, m: message.messageText ?? "")
//                    .padding(.horizontal)
//                    .padding(.top, message == messages.first ? 20 : 0) // Top padding only for the first message
//                }
//              }
//              .padding(.top)
//            }
//          }
//
//          // Input Field Section
//          HStack {
//            TextField("Type a message...", text: $newMessage)
//              .textFieldStyle(RoundedBorderTextFieldStyle()) // Round the text field
//              .padding(.leading, 10)
//              .padding(.vertical, 8)
//              .frame(height: 40)
//              .background(Color.white)
//              .cornerRadius(20)
//              .shadow(radius: 2)
//              .frame(maxWidth: geometry.size.width * 0.75) // Dynamic width for the text field
//
//            Button(action: {
//              viewModel.vmssid = session
//              viewModel.sendMessage(newMessage: newMessage)
//              newMessage = ""
//            }) {
//              Image(systemName: "arrow.up.circle.fill")
//                .font(.title)
//                .foregroundColor(.blue)
//            }
//            .disabled(newMessage.isEmpty)
//            .padding(.trailing, 10)
//            .frame(maxHeight: 40)
//          }
//          .background(Color(UIColor.systemGray6))
//          .cornerRadius(30)
//          .padding(.horizontal)
//          .padding(.bottom, geometry.safeAreaInsets.bottom + 10) // Add bottom padding for safe area
//        }
//        .navigationTitle("Chat")
//        .navigationBarTitleDisplayMode(.inline)
//      }
//    }
//    .edgesIgnoringSafeArea(.bottom) // Allow content to ignore the safe area at the bottom
//  }
//}
//
//struct MessageBubble: View {
//  let message: ChatMessageModel
//  let m: String
//
//  var body: some View {
//    HStack {
//      if message.role == .user {
//        Spacer()
//      }
//
//      VStack(
//        alignment: message.role == .user ? .trailing : .leading
//      ) {
//        Text(m)
//          .padding()
//          .background(
//            message.role == .user ? Color.blue : Color.gray.opacity(0.2)
//          )
//          .foregroundColor(
//            message.role == .user ? .white : .primary
//          )
//          .cornerRadius(16)
//          .animation(
//            .easeInOut,
//            value: message.messageText
//          )
//      }
//
//      if message.role == .Bot {
//        Spacer()
//      }
//    }
//    .padding(.horizontal)
//    .padding(.top, 4)
//  }
//}

struct NewSessionView: View {
  
  var session: String
  @State var newMessage: String = ""
  @Query private var messages: [ChatMessageModel]
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundImage: UIImage?
  
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
    GeometryReader { geometry in
      ZStack {
        
        // Background Image or Color
        if let backgroundImage = backgroundImage {
          Image(uiImage: backgroundImage)
            .resizable()
            .scaledToFill()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .edgesIgnoringSafeArea(.all)
        } else {
          Color.white
            .edgesIgnoringSafeArea(.all)
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
              .padding(.top)
            }
          }

          textfieldView(geometry: geometry)
            .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    .edgesIgnoringSafeArea(.bottom)
  }
  
  private func textfieldView(geometry: GeometryProxy) -> some View {
    HStack(alignment: .center, spacing: 10) {
      TextField("Start typing here...", text: $newMessage, onCommit: {
        guard !newMessage.isEmpty else { return }
        sendMessage(newMessage)
      })
      .padding(.leading, 10)
      .padding(.vertical, 8)
      .frame(height: 40)
      .background(Color.white)
      .cornerRadius(12)
      .shadow(radius: 2)
      .frame(maxWidth: geometry.size.width * 0.75)
      .textFieldStyle(RoundedBorderTextFieldStyle())

      // Send Button (simple button without icon)
      Button(action: {
        guard !newMessage.isEmpty else { return }
        sendMessage(newMessage)
      }) {
        Text("Send")
          .foregroundColor(.blue)
          .padding(.horizontal)
          .padding(.vertical, 10)
          .background(Color.blue.opacity(0.1))
          .cornerRadius(8)
      }
      .disabled(newMessage.isEmpty)
      .frame(maxHeight: 40)
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white)
    .cornerRadius(12)
    .padding(.horizontal, 20)
    .padding(.top, 10)
  }

  // Function to send the message
  private func sendMessage(_ message: String) {
    viewModel.vmssid = session
    viewModel.sendMessage(newMessage: message)
    newMessage = "" // Clear input field
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
          .padding()
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
