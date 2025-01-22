//
//  ActiveChatView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData
import MarkdownUI

public struct ActiveChatView: View {
  @State var session: String
  @State var newMessage: String = ""
  @Query private var messages: [ChatMessageModel]
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundColor: Color?
  @FocusState private var isTextFieldFocused: Bool
  @State private var scrollToBottom = false
  private var patientName: String?
  @Environment(\.dismiss) var dismiss
  private var calledFromPatientContext: Bool
  private var subTitle: String = "Ask anything.."
  @State private var hasFocusedOnce = false
  
  init(session: String, viewModel: ChatViewModel, backgroundColor: Color?, patientName: String, calledFromPatientContext: Bool) {
    self.session = session
    _messages = Query(
      filter: #Predicate<ChatMessageModel> { message in
        message.sessionData?.sessionId == session
      },
      sort: \.msgId,
      order: .forward
    )
    self.viewModel = viewModel
    self.backgroundColor = backgroundColor
    self.patientName = patientName
    self.calledFromPatientContext = calledFromPatientContext
  }
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ZStack {
        VStack {
          Image(.bg)
            .resizable()
            .frame(height: 120)
            .edgesIgnoringSafeArea(.all)
          Spacer()
        }
        VStack {
          ZStack {
            content
          }
        }
      }
    }
  }

  private var content: some View {
      VStack {
          if calledFromPatientContext {
              headerView
          }
          newView
          .background(Color(red: 0.96, green: 0.96, blue: 0.96))
      }
  }
  
  var EmptyChatView: some View {
    VStack {
      VStack {
        Spacer()
        if let image = SetUIComponents.shared.emptyChatImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 40)
        }
        
        DocSuggestion(image: UIImage(resource: .chatMsgGray) ,title: "Ask anything from DocAssist AI", subTitle: "Medical fact checks, prescriptions and more..")
          .padding()
        DocSuggestion(image: UIImage(resource: .voiceToRxBW), title: "Create medical document", subTitle: "DocAssist AI can either listen to your live consultation or your dictation to create a medical document")
        Spacer()
      }
      chatInputView
        .padding(.bottom, 5)
    }
  }
  
  var newView: some View {
      VStack {
        if messages.isEmpty {
          EmptyChatView
        }
        else {
          ScrollViewReader { proxy in
            ScrollView {
              VStack {
                ForEach(messages) { message in
                  MessageBubble(message: message, m: message.messageText ?? "No message")
                    .padding(.horizontal)
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
          chatInputView
            .padding(.bottom, 5)
        }
      }
      .navigationTitle("New Chat")
      .navigationBarTitleDisplayMode(.large)
  }
  
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
              .font(Font.custom("Lato-Regular", size: 16))
              .foregroundColor(Color(red: 0.13, green: 0.37, blue: 1))
            Spacer()
          }
        }
        .contentShape(Rectangle())
        Spacer()
      }
      .padding(.leading, 10)
      .padding(.top, 9)
      
      VStack(alignment: .leading, spacing: 0) {
        Text("New chat")
          .font(
            Font.custom("Lato-Bold", size: 34)
          )
          .foregroundColor(Color(red: 0.35, green: 0.03, blue: 0.5))
        
        Text("Parrotlet Lite")
          .font(Font.custom("Lato-Regular", size: 14))
          .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .padding(.horizontal, 16)
      .padding(.top, 3)
      .padding(.bottom, 8)
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .padding(.bottom, 5)
  }
  
  var chatInputView : some View {
    VStack (spacing: 15) {
      HStack {
        TextField(" Start typing...", text: $newMessage, axis: .vertical)
      }
      
      HStack(spacing: 10) {
        
        Button {
          
        } label: {
          Image(systemName: "paperclip")
            .foregroundStyle(Color.neutrals600)
        }
        
        Button {
          
        } label: {
          Image(systemName: "photo")
            .foregroundStyle(Color.neutrals600)
        }
        
        if let patientName = patientName , !patientName.isEmpty,
            patientName != "General Chat" {
          HStack(alignment: .center, spacing: 4) {
            VStack(alignment: .center, spacing: 10) {
              Image(systemName: "person.fill")
            }
            .padding(4)
            .frame(width: 16, height: 16, alignment: .center)
            
            
            Text(patientName)
              .font(
                Font.custom("Lato-Bold", size: 12)
              )
              .foregroundColor(Color(red: 0.28, green: 0.28, blue: 0.28))
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .background(Color(red: 0.91, green: 0.91, blue: 0.91))
          .cornerRadius(123)
        } else {
          Image(.user)
        }
        
        Spacer()
        
        Button {
          
        } label: {
          Image(systemName: "microphone")
            .foregroundStyle(Color.neutrals600)
        }
        
        Button {
          newMessage = viewModel.trimLeadingSpaces(from: newMessage)
           guard !newMessage.isEmpty else { return }
           sendMessage(newMessage)
        } label: {
          if newMessage.isEmpty {
            Image(.voiceToRxButton)
          } else {
            Image(systemName: "arrow.up")
                   .foregroundStyle(Color.white)
                   .fontWeight(.bold)
                   .padding(4)
                   .background(Circle().fill(Color.blue))
          }
        }
        
      }
    }
    .padding(8)
    .background(Color(.white))
    .cornerRadius(20)
    .overlay(content: {
       RoundedRectangle(cornerRadius:20)
        .stroke(Color.gray, lineWidth: 0.5)
    })
    .padding(8)
  }
  
  private func sendMessage(_ message: String) {
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
    Markdown(text)
      .padding(8)
      .background(backgroundColor)
      .foregroundColor(foregroundColor)
      .contentTransition(.numericText())
      .customCornerRadius(12, corners: [.bottomLeft, .bottomRight, .topLeft])
  }
  
  private var backgroundColor: Color {
    role == .user ? (SetUIComponents.shared.userBackGroundColor ?? .white) : (SetUIComponents.shared.botBackGroundColor ?? .clear)
  }
  
  private var foregroundColor: Color {
    role == .user ? (SetUIComponents.shared.usertextColor ?? Color(red: 0.1, green: 0.1, blue: 0.1)) : (Color(red: 0.28, green: 0.28, blue: 0.28))
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

extension View {
  func customCornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
    clipShape(CustomCornerShape(cornerRadius: radius, corners: corners))
  }
}

struct CustomCornerShape: Shape {
  var cornerRadius: CGFloat
  var corners: UIRectCorner
  
  func path(in rect: CGRect) -> Path {
    let path = UIBezierPath(
      roundedRect: rect,
      byRoundingCorners: corners,
      cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
    )
    return Path(path.cgPath)
  }
}

struct DocSuggestion: View {
  
  var image: UIImage
  var title: String
  var subTitle: String
  
  init(image: UIImage, title: String, subTitle: String) {
    self.image = image
    self.title = title
    self.subTitle = subTitle
  }
  
  var body: some View {
    
    HStack(alignment: .top, spacing: 12) {
      Spacer()
      Image(uiImage: image)
        .frame(width: 24)
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .foregroundStyle(Color.neutrals600)
          .font(.custom("Lato-Bold", size: 16))
          .frame(maxWidth: .infinity, alignment: .leading)
        Text(subTitle)
          .foregroundStyle(Color.neutrals600)
          .font(.custom("Lato-Regular", size: 13))
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(width: 260)
      Spacer()
    }
  }
}
