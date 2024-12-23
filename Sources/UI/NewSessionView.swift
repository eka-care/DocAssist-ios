//
//  NewSessionView.swift
//  Chatbot
//
//  Created by Brunda B on 15/11/24.
//

import SwiftUI
import SwiftData

public struct NewSessionView: View {
  @State var session: String
  @State var newMessage: String = ""
  @Query private var messages: [ChatMessageModel]
  @ObservedObject private var viewModel: ChatViewModel
  var backgroundColor: Color?
  @FocusState private var isTextFieldFocused: Bool
  @State private var scrollToBottom = false
  private var patientName: String? = "General Chat"
  @Environment(\.dismiss) var dismiss
  private var calledFromPatientContext: Bool
  private var subTitle: String = "Ask anything.."
  @State private var hasFocusedOnce = false
  private var suggestionsTextsForPatientContext: [String] = ["💉 Generate a vaccination chart for an infant","🥬 Generate a diet chart","🏋️‍♀️ Give lifestyle advice for a patient","👨🏻‍⚖️ How can I minimise medico-legal risks?"]
  private var suggestionsTextForGeneralChat: [String] = ["💉 Generate a vaccination chart for an infant","🥬 Diet for hyperuricemia","📄 Should moxclav to be given in pregnancy?","👨🏻‍⚖️ How can I minimise medico-legal risks?"]
  
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
  
public  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let backgroundColor {
        VStack {
          if calledFromPatientContext {
            headerView
          }
          newView
        }
          .background(backgroundColor)
        
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
            .font(.custom("Lato-Bold", size: 20))
            .fontWeight(.medium)
            .padding(.top, 5)
          
          if calledFromPatientContext {
            Group {
              Text("Doc Assist uses the patient data and prescription")
              Text("data to generate responses")
            }
              .foregroundStyle(.secondary)
              .font(.subheadline)
          }
          
          let suggestions = calledFromPatientContext ? suggestionsTextsForPatientContext : suggestionsTextForGeneralChat

          ForEach(suggestions, id: \.self) { suggestion in
              SuggestionView(suggestionText: suggestion, viewModel: viewModel)
                  .padding(.all, 4)
          }
          
          Spacer()
          textfieldView
            .padding(.bottom, 5)
        }
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            LazyVStack {
              ForEach(messages) { message in
                MessageBubble(message: message, m: message.messageText ?? "afdf")
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
        textfieldView
          .padding(.bottom, 5)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .principal) {
            VStack {
              Text(patientName ?? "General Chat")
                    .font(.headline)
                    .foregroundColor(.primary)
              Text(subTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
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
            Spacer()
            VStack {
              Text(patientName ?? "General Chat")
                .font(.headline)
                .foregroundColor(.primary)
              Text("Ask anything about this patient")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
          }
        }
        .contentShape(Rectangle())
        Spacer()
      }
      .padding(.leading, 10)
      .padding(.top, 9)
    }
    .padding(.bottom, 5)
    .background(Color.white)
  }
  
  var textfieldView: some View {
    ZStack {
      HStack {
        TextField("  Start typing...", text: $newMessage, axis: .vertical)
          .padding(.horizontal, 12)
          .padding(.vertical, 10)
          .font(.body)
          .focused($isTextFieldFocused)
          .onChange(of: viewModel.voiceText) { _ , newVoiceText in
            if let voiceText = newVoiceText, !voiceText.isEmpty {
              newMessage = voiceText
              viewModel.voiceText = ""
            }
          }
        VStack {
          Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
            .foregroundColor(.gray.opacity(0.5))
            .font(.system(size: 20))
            .onTapGesture {
              viewModel.isRecording ? viewModel.stopRecording() : viewModel.startRecording()
            }
        }
        Button(action: {
          newMessage = viewModel.trimLeadingSpaces(from: newMessage)
          guard !newMessage.isEmpty else { return }
          sendMessage(newMessage)
          isTextFieldFocused.toggle()
        }) {
          Image(systemName: "arrow.up")
            .foregroundStyle(Color.white)
            .fontWeight(.bold)
            .padding(4)
            .background(Circle().fill((newMessage.isEmpty || viewModel.streamStarted) ? Color.gray.opacity(0.4) : Color.blue))
        }
        .disabled(newMessage.isEmpty)
        .disabled(viewModel.streamStarted)
      }
      .padding(.horizontal, 12)
      .background(RoundedRectangle(cornerRadius: 30).fill(Color.white))
      .overlay {
        RoundedRectangle(cornerRadius: 30)
          .stroke(
            isTextFieldFocused ? Color.myColor : Color.clear,
            lineWidth: 1
          )
      }
    }
    .padding(.horizontal, 16)
    .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 16 : 0)
    .onAppear {
      if !hasFocusedOnce, !messages.isEmpty {
        isTextFieldFocused = true
        hasFocusedOnce = true
      }
    }
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
    Text(.init(text))
      .padding(8)
      .background(backgroundColor)
      .foregroundColor(foregroundColor)
      .contentTransition(.numericText())
      .customCornerRadius(12, corners: [.bottomLeft, .bottomRight, .topLeft])
  }
  
  private var backgroundColor: Color {
    role == .user ? (SetUIComponents.shared.userBackGroundColor ?? .blue) : (SetUIComponents.shared.botBackGroundColor ?? .clear)
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

struct SuggestionView: View {
  
  var suggestionText: String = ""
  var viewModel: ChatViewModel
  
  init(suggestionText: String, viewModel: ChatViewModel) {
    self.suggestionText = suggestionText
    self.viewModel = viewModel
  }
  
  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20)
        .frame(width: 360, height: 40)
        .foregroundStyle(Color.nuetralWhite)
      Button(action: {
        viewModel.sendMessage(newMessage: suggestionText)
      }) {
        HStack {
          Text(suggestionText)
            .foregroundColor(Color.primary)
            .lineLimit(1)
            .padding(.leading, 10)
          Spacer()
        }
      }
    }
    .frame(width: 360, height: 40)
  }
}
