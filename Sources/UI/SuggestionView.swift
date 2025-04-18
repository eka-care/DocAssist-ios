//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 06/01/25.
//

import SwiftUI

struct SuggestionView: View {
  
  var suggestionText: [String]
  var viewModel: ChatViewModel
  var lastMessageId: Int?
  
  private var constantSuggestionString = "Suggested questions you can ask me-"
  private var constantGetMoreSuggestion = "Get more suggestions"
  private var constantLoadingSuggestion = "Loading more suggestions..."
  private var constantNoSuggestion = "No more new suggestions found :("
  
  init(suggestionText: [String], viewModel: ChatViewModel, lastMessageId: Int? = nil) {
    self.suggestionText = suggestionText
    self.viewModel = viewModel
    self.lastMessageId = lastMessageId
  }
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack(alignment: .center, spacing: 8) {
        BotAvatarImage()
        
        Text(constantSuggestionString)
          .font(.custom("Lato-Regular", size: 12))
          .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
      }
      .padding(.bottom, 4)
      
      VStack(alignment: .leading, spacing: 8) {
        ForEach(suggestionText, id: \.self) { suggestionText in
          Button(action: {
            guard let lastMessageId else { return }
            if !viewModel.streamStarted {
              Task {
                await viewModel.sendMessage(newMessage: suggestionText, imageUrls: nil, vaultFiles: nil, sessionId: viewModel.vmssid, lastMesssageId: lastMessageId)
              }
            }
          }) {
            Text(suggestionText)
              .foregroundColor(viewModel.streamStarted ? Color.white : Color.primaryprimary)
              .font(.custom("Lato-Regular", size: 14))
              .multilineTextAlignment(.leading)
              .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(viewModel.streamStarted ? Color.gray.opacity(0.3) : .white)
              .clipShape(RoundedRectangle(cornerRadius: 12))
          }
        }
      }
      .padding(.leading, 20)
      .padding(.trailing, 20)
    }
  }
}
